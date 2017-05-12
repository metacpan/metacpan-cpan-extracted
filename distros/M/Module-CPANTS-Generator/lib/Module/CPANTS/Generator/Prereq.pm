package Module::CPANTS::Generator::Prereq;
use strict;
use Carp;
use File::Spec::Functions;
use vars qw($recursive $requires $VERSION);
use Module::CPANTS::Generator;
use base 'Module::CPANTS::Generator';
$VERSION = "0.005";

sub generate {
  my $self = shift;

  my $cpants = $self->grab_cpants;
  my $cp = $self->cpanplus || croak("No CPANPLUS object");

  my $count = 0;
  my $total;
  local($requires, $recursive);
  my($requires_module);

  foreach my $dist (sort grep { -d } <*>) {
    my $filename = catfile($dist, 'Makefile.PL');
    $count++;
    next unless -f $filename;

    open(IN, $filename);
    my $m = join '', <IN>;
    close IN;

    my $p = $1 if $m =~ m/PREREQ_PM.*?=>.*?\{(.*?)\}/s;
    next unless $p;
    # get rid of lines which are only comments
    $p = join "\n", grep { $_ !~ /^\s*#/ } split "\n", $p;
    # get rid of empty lines
    $p = join "\n", grep { $_ !~ /^\s*$/ } split "\n", $p;

    if ($p =~ /=>/ or $p =~ /,/) {
      my $prereqs;
      my $code = "{no strict; \$prereqs = { $p\n}}";
      eval $code;
#    print "WARN: $p\n$@\n" if $@;
      foreach my $k (sort keys %$prereqs) {
	my $d2 = $cp->module_tree->{$k};
	if (not defined $d2) {
#	print "$k not found ($dist)\n";
	  next;
	}
	$requires_module->{$dist}->{$k} = $prereqs->{$k};
	$requires->{$dist}->{$d2->package}++;
	$total->{$k}++;
      }
    } elsif ($p) {
#    print "??? uhoh: $p\n";
    }
  }

  foreach my $o (sort keys %$requires) {
    foreach my $p (sort keys %{$requires->{$o}}) {
      $self->fill($o, $p);
    }
  }

  my $requires_array = $self->fold($requires);
  my $recursive_array = $self->fold($recursive);

  foreach my $k (keys %$requires) {
    $cpants->{cpants}->{$k}->{requires_module} = $requires_module->{$k};
    $cpants->{cpants}->{$k}->{requires} = $requires_array->{$k};
    $cpants->{cpants}->{$k}->{requires_recursive} = $recursive_array->{$k};
  }

  $self->save_cpants($cpants);
  return $count;
}

sub fill {
  my($self, $key, $value) = @_;
  return if $recursive->{$key}->{$value}++;

  my $c = $requires->{$value};
  foreach my $d (sort keys %$c) {
    $self->fill($key, $d);
  }
}

sub fold {
  my($self, $hash) = @_;
  my $folded;
  foreach my $d (sort keys %$hash) {
    $folded->{$d} = [sort keys %{$hash->{$d}}];
  }
  return $folded;
}

1;


__END__

=head1 NAME

Module::CPANTS::Generator::Prereq - Generate prereq

=head1 SYNOPSIS

  use Module::CPANTS::Generator::Prereq;

  my $p = Module::CPANTS::Generator::Prereq->new;
  $p->cpanplus($cpanplus);
  $p->directory("unpacked");
  $p->generate;

=head1 DESCRIPTION

This module is part of the beta CPANTS project. It scans through an
unpacked CPAN looking for Makefile.PLs and adds prerequisite informatin.

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 LICENSE

This code is distributed under the same license as Perl.
