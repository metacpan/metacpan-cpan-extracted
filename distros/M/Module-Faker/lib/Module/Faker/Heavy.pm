use strict;
use warnings;
package Module::Faker::Heavy;
# ABSTRACT: where the fake sausage gets made
$Module::Faker::Heavy::VERSION = '0.017';
use Carp ();
use Text::Template;

my $template;
sub _template {
  return $template if $template;

  my $current;
  while (my $line = <DATA>) {
    chomp $line;
    if ($line =~ /\A__([^_]+)__\z/) {
      my $filename = $1;
      if ($filename !~ /\A(?:DATA|END)\z/) {
        $current = $filename;
        next;
      }
    }

    Carp::confess "bogus data section: text outside of file" unless $current;

    ($template->{$current} ||= '') .= "$line\n";
  }

  return $template;
}

sub _render {
  my ($self, $name, $stash) = @_;

  Carp::confess "no file template for $name" unless
    my $template = $self->_template->{ $name };

  my $text = Text::Template->fill_this_in(
    $template,
    DELIMITERS => [ '{{', '}}' ],
    HASH       => { map {; $_ => \($stash->{$_}) } keys %$stash },
  );

  return $text;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Module::Faker::Heavy - where the fake sausage gets made

=head1 VERSION

version 0.017

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__META.yml__
---
name: {{ $dist->name }}
version: {{ $dist->version }}
abstract: {{ $dist->abstract }}
author:
{{ $OUT .= sprintf "  - %s\n", $_ for $dist->authors; chomp $OUT; return }}
generated_by: Module::Faker version {{ $Module::Faker::VERSION }}
license: unknown{{ if (my %requires = $dist->requires) {
  $OUT .= "\nrequires:";
  $OUT .= sprintf "\n  %s: %s", $_, (defined $requires{$_} ? $requires{$_} : '~') for keys %requires;
  chomp $OUT;
}
return;
}}
meta-spec: 
  url: http://module-build.sourceforge.net/META-spec-v1.3.html
  version: 1.3
__Makefile.PL__
use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME => "{{ $dist->name }}",
  NAME     => "{{ $dist->_pkgy_name }}",
  VERSION  => "{{ $dist->version }}",
  ABSTRACT => '{{ my $abs = $dist->abstract; $abs =~ s/'/\'/g; $abs }}',
  PREREQ_PM => { {{
if (my %requires = $dist->_flat_prereqs ) {
  $OUT .= sprintf "\n    '%s' => '%s',", $_,
    (defined $requires{$_} ?  $requires{$_} : 0) for sort keys %requires;
}
return;
  }}
  },
);
__t/00-nop.t__
#!perl
use Test::More tests => 1;
ok(1);
