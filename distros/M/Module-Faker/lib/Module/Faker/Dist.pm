package Module::Faker::Dist;
# ABSTRACT: a fake CPAN distribution
$Module::Faker::Dist::VERSION = '0.017';
use Moose;


use Module::Faker::File;
use Module::Faker::Heavy;
use Module::Faker::Package;
use Module::Faker::Module;

use Archive::Any::Create;
use CPAN::DistnameInfo;
use CPAN::Meta 2.130880; # github issue #9
use CPAN::Meta::Requirements;
use File::Temp ();
use File::Path ();
use Parse::CPAN::Meta 1.4401;
use Path::Class;
use Encode qw( encode_utf8 );

# Module::Faker options
has cpan_author  => (is => 'ro', isa => 'Maybe[Str]', default => 'LOCAL');
has archive_ext  => (is => 'ro', isa => 'Str', default => 'tar.gz');
has append       => (is => 'ro', isa => 'ArrayRef[HashRef]', default => sub {[]});
has mtime        => (is => 'ro', isa => 'Int', predicate => 'has_mtime');

# required by CPAN::Meta::Spec
has name           => (is => 'ro', isa => 'Str', required => 1);
has version        => (is => 'ro', isa => 'Maybe[Str]', default => '0.01');
has abstract       => (is => 'ro', isa => 'Str', default => 'a great new dist');
has release_status => (is => 'ro', isa => 'Str', default => 'stable');

has license => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [ 'perl_5' ] },
);

has authors => (
  isa  => 'ArrayRef[Str]',
  lazy => 1,
  traits  => [ 'Array' ],
  handles => { authors => 'elements' },
  default => sub {
    my ($self) = @_;
    return [ sprintf '%s <%s@cpan.local>', ($self->cpan_author) x 2 ];
  },
);

# optional CPAN::Meta::Spec fields
has provides => (
  is => 'ro',
  isa => 'HashRef',
  lazy_build => 1,
);

sub _build_provides {
  my ($self) = @_;
  my $pkg = __dist_to_pkg($self->name);
  return {
    $pkg => {
      version => $self->version,
      file => __pkg_to_file($pkg),
    }
  };
};

sub __dor { defined $_[0] ? $_[0] : $_[1] }

sub append_for {
  my ($self, $filename) = @_;
  return [
    # YAML and JSON should both be in utf8 (if not plain ascii)
    map  { encode_utf8($_->{content}) }
    grep { $filename eq $_->{file} }
      @{ $self->append }
  ];
}

has archive_basename => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    return sprintf '%s-%s', $self->name, __dor($self->version, 'undef');
  },
);

sub __dist_to_pkg { my $str = shift; $str =~ s/-/::/g; return $str; }
sub __pkg_to_file { my $str = shift; $str =~ s{::}{/}g; return "lib/$str.pm"; }

# This is stupid, but copes with MakeMaker wanting to have a module name as its
# NAME parameter.  Ugh! -- rjbs, 2008-03-13
sub _pkgy_name {
  my $name = shift->name;
  $name =~ s/-/::/g;

  return $name;
}

has packages => (
  is          => 'ro',
  isa         => 'Module::Faker::Type::Packages',
  lazy_build  => 1,
  auto_deref => 1,
);

sub _build_packages {
  my ($self) = @_;

  my $href = $self->provides;

  # do this dance so we don't autovivify X_Module_Faker in provides
  my %package_order = map {;
    $_ => (exists $href->{$_}{X_Module_Faker} ? $href->{$_}{X_Module_Faker}{order} : 0 )
  } keys %$href;

  my @pkg_names = do {
    no warnings 'uninitialized';
    sort { $package_order{$a} <=> $package_order{$b} } keys %package_order;
  };

  my @packages;
  for my $name (@pkg_names) {
    push @packages, Module::Faker::Package->new({
      name    => $name,
      version => $href->{$name}{version},
      in_file => $href->{$name}{file},
    });
  }

  return \@packages;
}

sub modules {
  my ($self) = @_;

  my %module;
  for my $pkg ($self->packages) {
    my $filename = $pkg->in_file;

    push @{ $module{ $filename } ||= [] }, $pkg;
  }

  my @modules = map {
    Module::Faker::Module->new({
      packages => $module{$_},
      filename => $_,
      append   => $self->append_for($_)
    });
  } keys %module;

  return @modules;
}

sub _mk_container_path {
  my ($self, $filename) = @_;

  my (@parts) = File::Spec->splitdir($filename);
  my $leaf_filename = pop @parts;
  File::Path::mkpath(File::Spec->catdir(@parts));
}

sub make_dist_dir {
  my ($self, $arg) = @_;
  $arg ||= {};

  my $dir = $arg->{dir} || File::Temp::tempdir;
  my $dist_dir = File::Spec->catdir($dir, $self->archive_basename);

  for my $file ($self->files) {
    my $fqfn = File::Spec->catfile($dist_dir, $file->filename);
    $self->_mk_container_path($fqfn);

    open my $fh, '>', $fqfn or die "couldn't open $fqfn for writing: $!";
    print $fh $file->as_string;
    close $fh or die "error when closing $fqfn: $!";
  }

  return $dist_dir;
}

sub _author_dir_infix {
  my ($self) = @_;

  Carp::croak "can't put archive in author dir with no author defined"
    unless my $pauseid = $self->cpan_author;

  # Sorta like pow- pow- power-wheels! -- rjbs, 2008-03-14
  my ($pa, $p) = $pauseid =~ /^((.).)/;
  return ($p, $pa, $pauseid);
}

sub archive_filename {
  my ($self, $arg) = @_;

  my $base = $self->archive_basename;
  my $ext  = $self->archive_ext;

  return File::Spec->catfile(
    ($arg->{author_prefix} ? $self->_author_dir_infix : ()),
    "$base.$ext",
  );
}

sub make_archive {
  my ($self, $arg) = @_;
  $arg ||= {};

  my $dir = $arg->{dir} || File::Temp::tempdir;

  my $archive   = Archive::Any::Create->new;
  my $container = $self->archive_basename;

  $archive->container($container);

  for my $file ($self->files) {
    $archive->add_file($file->filename, $file->as_string);
  }

  my $archive_filename = File::Spec->catfile(
    $dir,
    $self->archive_filename({ author_prefix => $arg->{author_prefix} })
  );

  $self->_mk_container_path($archive_filename);
  $archive->write_file($archive_filename);
  utime time, $self->mtime, $archive_filename if $self->has_mtime;
  return $archive_filename;
}

sub files {
  my ($self) = @_;
  my @files = ($self->modules, $self->_extras, $self->_manifest_file);
  for my $file (@{$self->append}) {
    next if(grep { $_->filename eq $file->{file} } @files);
    push(@files,
      $self->_file_class->new(
        filename => $file->{file},
        content  => '',
        append   => $self->append_for($file->{file}),
      ) );
  }
  return @files;
}

sub _file_class { 'Module::Faker::File' }

has omitted_files => (
  is   => 'ro',
  isa  => 'ArrayRef[Str]',
  auto_deref => 1,
);

around BUILDARGS => sub {
  my ($orig, $self, @rest) = @_;
  my $arg = $self->$orig(@rest);

  confess "can't supply both requires and prereqs"
    if $arg->{prereqs} && $arg->{requires};

  if ($arg->{requires}) {
    $arg->{prereqs} = {
      runtime => { requires => delete $arg->{requires} }
    };
  }

  return $arg;
};

has prereqs => (
  is   => 'ro',
  isa  => 'HashRef',
  default    => sub {  {}  },
  auto_deref => 1,
);

has _manifest_file => (
  is   => 'ro',
  isa  => 'Module::Faker::File',
  lazy => 1,
  default => sub {
    my ($self) = @_;
    my @files = ($self->modules, $self->_extras);

    return $self->_file_class->new({
      filename => 'MANIFEST',
      content  => join("\n",
        'MANIFEST',
        map { $_->filename } @files
      ),
    });
  },
);

has _cpan_meta => (
  is => 'ro',
  isa => 'CPAN::Meta',
  lazy_build => 1,
);

sub _build__cpan_meta {
  my ($self) = @_;
  my $meta = {
    'meta-spec' => { version => '2' },
    dynamic_config => 0,
    author => [ $self->authors ], # plural attribute that derefs
  };
  # required fields
  for my $key ( qw/abstract license name release_status version/ ) {
    $meta->{$key} = $self->$key;
  }
  # optional fields
  for my $key ( qw/provides prereqs/ ) {
    $meta->{$key} = $self->$key;
  }
  return CPAN::Meta->new( $meta, {lazy_validation => 1} );
}

has _extras => (
  is   => 'ro',
  isa  => 'ArrayRef[Module::Faker::File]',
  lazy => 1,
  auto_deref => 1,
  default    => sub {
    my ($self) = @_;
    my @files;

    for my $filename (qw(Makefile.PL t/00-nop.t)) {
      next if grep { $_ eq $filename } $self->omitted_files;
      push @files, $self->_file_class->new({
        filename => $filename,
        content  => Module::Faker::Heavy->_render(
          $filename,
          { dist => $self },
        ),
      });
    }

    unless ( grep { $_ eq 'META.json' } $self->omitted_files ) {
      push @files, $self->_file_class->new({
        filename => 'META.json',
        content  => $self->_cpan_meta->as_string( { version => "2" } ),
      });
    }

    unless ( grep { $_ eq 'META.yml' } $self->omitted_files ) {
      push @files, $self->_file_class->new({
        filename => 'META.yml',
        content  => $self->_cpan_meta->as_string( { version => "1.4" } ),
      });
    }

    return \@files;
  },
);

# TODO: make this a registry -- rjbs, 2008-03-12
my %HANDLER_FOR = (
  yaml => '_from_meta_file',
  yml  => '_from_meta_file',
  json => '_from_meta_file',
  dist => '_from_distnameinfo'
);

sub from_file {
  my ($self, $filename) = @_;

  my ($ext) = $filename =~ /.*\.(.+?)\z/;

  Carp::croak "don't know how to handle file $filename"
    unless $ext and my $method = $HANDLER_FOR{$ext};

  $self->$method($filename);
}

sub _from_distnameinfo {
  my ($self, $filename) = @_;
  $filename = file($filename)->basename;
  $filename =~ s/\.dist$//;

  my ($author, $path) = split /_/, $filename, 2;

  my $dni = CPAN::DistnameInfo->new($path);

  return $self->new({
    name     => $dni->dist,
    version  => $dni->version,
    abstract => sprintf('the %s dist', $dni->dist),
    archive_ext => $dni->extension,
    cpan_author => $author,
  });
}

sub _from_meta_file {
  my ($self, $filename) = @_;

  my $data = Parse::CPAN::Meta->load_file($filename);
  my $extra = (delete $data->{X_Module_Faker}) || {};
  my $dist = $self->new({ %$data, %$extra });
}

sub _flat_prereqs {
  my ($self) = @_;
  my $prereqs = $self->_cpan_meta->effective_prereqs;
  my $req = CPAN::Meta::Requirements->new;
  for my $phase ( qw/runtime build test/ ) {
    $req->add_requirements( $prereqs->requirements_for( $phase, 'requires' ) );
  }
  return %{ $req->as_string_hash };
}

1;

# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Faker::Dist - a fake CPAN distribution

=head1 VERSION

version 0.017

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
