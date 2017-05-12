package Perl::PrereqScanner::NotQuiteLite::App;

use strict;
use warnings;
use File::Find;
use File::Basename;
use File::Spec;
use CPAN::Meta::Prereqs;
use CPAN::Meta::Requirements;
use Perl::PrereqScanner::NotQuiteLite;

sub new {
  my ($class, %opts) = @_;

  for my $key (keys %opts) {
    next unless $key =~ /\-/;
    (my $replaced_key = $key) =~ s/\-/_/g;
    $opts{$replaced_key} = $opts{$key};
  }

  $opts{prereqs} = CPAN::Meta::Prereqs->new;
  $opts{parsers} = [':installed'] unless defined $opts{parsers};
  $opts{suggests} = 0 unless defined $opts{suggests};
  $opts{base_dir} ||= File::Spec->curdir;

  bless \%opts, $class;
}

sub run {
  my ($self, @args) = @_;

  unless (@args) {
    # for configure requires
    push @args, "Makefile.PL", "Build.PL";

    # for test requires
    push @args, "t";

    # for runtime requires;
    if ($self->{blib} and -d File::Spec->catdir($self->{base_dir}, 'blib')) {
      push @args, "blib/lib", "blib/bin", "blib/script";
    } else {
      push @args, "lib";
      push @args, glob(File::Spec->catfile($self->{base_dir}, '*.pm'));
      push @args, "bin", "script", "scripts";
    }

    # for develop requires
    push @args, "xt", "author", "inc" if $self->{develop};
  }

  for my $path (@args) {
    my $item = File::Spec->file_name_is_absolute($path) ? $path : File::Spec->catfile($self->{base_dir}, $path);
    -d $item ? $self->_scan_dir($item) :
    -f $item ? $self->_scan_file($item) :
    next;
  }

  $self->_exclude_local_modules;

  if ($self->{exclude_core} or $self->{perl_version}) {
    eval { require Module::CoreList; Module::CoreList->VERSION('2.99') } or die "requires Module::CoreList 2.99";
    $self->_exclude_core_prereqs;
  }

  if ($self->{print}) {
    if ($self->{json}) {
      eval { require JSON::PP } or die "requires JSON::PP";
      print JSON::PP->new->pretty(1)->canonical->encode($self->{prereqs}->as_string_hash);
    } else {
      $self->_print_prereqs;
    }
  }
  $self->{prereqs};
}

sub _print_prereqs {
  my $self = shift;

  my $combined = CPAN::Meta::Requirements->new;

  for my $req ($self->_requirements) {
    $combined->add_requirements($req);
  }
  my $hash = $combined->as_string_hash;
  for my $module (sort keys %$hash) {
    next if $module eq 'perl';
    my $version = $hash->{$module} || 0;
    $version = qq{"$version"} unless $version =~ /^[0-9]+(?:\.[0-9]+)?$/;
    print $version eq '0' ? "$module\n" : "$module~$version\n";
  }
}

sub _requirements {
  my $self = shift;

  my $prereqs = $self->{prereqs};
  my @phases = qw/configure runtime test/;
  push @phases, 'develop' if $self->{develop};
  my @types = $self->{suggests} ? qw/requires suggests/ : qw/requires/;
  my @requirements;
  for my $phase (@phases) {
    for my $type (@types) {
      my $req = $prereqs->requirements_for($phase, $type);
      next unless $req->required_modules;
      push @requirements, $req;
    }
  }
  @requirements;
}

sub _exclude_local_modules {
  my $self = shift;

  for my $req ($self->_requirements) {
    for my $module ($req->required_modules) {
      $req->clear_requirement($module) if $self->{possible_modules}{$module};
    }
  }
}

sub _exclude_core_prereqs {
  my $self = shift;

  my $perl_version = $self->{perl_version} || '5.008001';
  if ($perl_version =~ /^v?5\.([1-9][0-9]?)(?:\.([0-9]))?$/) {
    $perl_version = sprintf '5.%03d%03d', $1, $2 || 0;
  }
  $perl_version = '5.008001' unless exists $Module::CoreList::version{$perl_version};

  for my $req ($self->_requirements) {
    for my $module ($req->required_modules) {
      if (Module::CoreList::is_core($module) and
          !Module::CoreList::deprecated_in($module)
      ) {
        my $core_version = $Module::CoreList::version{$perl_version}{$module} or next;
        $req->clear_requirement($module) if $req->accepts_module($module => $core_version);
      }
    }
  }
  my $req = $self->{prereqs}->requirements_for('runtime', 'requires');
  $req->add_minimum(perl => $perl_version);
}

sub _scan_dir {
  my ($self, $dir) = @_;
  find ({
    no_chdir => 1,
    wanted => sub {
      my $file = $_;
      return unless -f $file;
      my $relpath = File::Spec->abs2rel($file, $self->{base_dir});

      return unless $relpath =~ /\.(?:pl|PL|pm|cgi|psgi|t)$/ or
                    dirname($relpath) =~ m!\b(?:bin|scripts?)$! or
                    ($self->{develop} and $relpath =~ /^(?:author)\b/);
      $self->_scan_file($relpath);
    },
  }, $dir);
}

sub _scan_file {
  my ($self, $file) = @_;

  my $context = Perl::PrereqScanner::NotQuiteLite->new(
    parsers => $self->{parsers},
    suggests => $self->{suggests},
  )->scan_file($file);

  if ($file =~ m!(?:^|[\\/])(?:Makefile|Build)\.PL$!) {
    $self->_add(configure => $context);
  } elsif ($file =~ m!(?:^|[\\/])t[\\/]!) {
    $self->_add(test => $context);
  } elsif ($file =~ m!(?:^|[\\/])(?:xt|inc|author)[\\/]!) {
    $self->_add(develop => $context);
  } else {
    $self->_add(runtime => $context);
  }

  if ($file =~ /\.pm$/) {
    my $module = $file;
    $module =~ s!\.pm$!!;
    $module =~ s![\\/]!::!g;
    $self->{possible_modules}{$module} = 1;
    $module =~ s!^(?:inc|blib|x?t)::!!;
    $self->{possible_modules}{$module} = 1;
    $module =~ s!^lib::!!;
    $self->{possible_modules}{$module} = 1;
  }
}

sub _add {
  my ($self, $phase, $context) = @_;

  my $prereqs = $self->{prereqs};

  $prereqs->requirements_for($phase, 'requires')
          ->add_requirements($context->requires);

  return unless $self->{suggests};

  $prereqs->requirements_for($phase, 'suggests')
          ->add_requirements($context->suggests);
}

1;

__END__

=encoding utf-8

=head1 NAME

Perl::PrereqScanner::NotQuiteLite::App

=head1 SYNOPSIS

=head1 DESCRIPTION

This is the guts of C<scan-perl-prereqs-nqlite>.

=head1 METHODS

=head2 new

creates an object. See C<scan-perl-prereqs-nqlite> for options.

=head2 run

traverses files and directories and returns a L<CPAN::Meta::Prereqs>
object that keeps all the requirements/suggestions, without printing
anything unless you explicitly pass a C<print> option to C<new>.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
