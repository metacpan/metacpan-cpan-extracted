package Module::Faker::Package 0.026;
# ABSTRACT: a faked package in a faked module

use v5.20.0;
use Moose;

use Moose::Util::TypeConstraints;

has name     => (is => 'ro', isa => 'Str', required => 1);
has version  => (is => 'ro', isa => 'Maybe[Str]');
has abstract => (is => 'ro', isa => 'Maybe[Str]');

has in_file  => (
  is       => 'ro',
  isa      => 'Str',
  lazy     => 1,
  default  => sub {
    my ($self) = @_;
    my $name = $self->name;
    $name =~ s{::}{/}g;
    return "lib/$name";
  },
);

# PKGWORD = package | class | role
# VERSION = our | our-literal | inline
# STYLE   = statement | block
#
#                           STYLE         VERSION
# PW N;  our $V = '...';    statement     our
# PW N;  our $V =  ... ;    statement     our-literal
# PW N V;                   statement     inline
# PW N { our $V = '...' }   block         our
# PW N { our $V =  ...  }   block         our-literal
# PW N V { ... }            block         inline

has layout => (
  reader  => '_layout',
  default => sub {
    return { pkgword => 'package', version => 'our', style => 'statement' };
  },
);

my %STYLE_TEMPLATE = (
  'statement_our'         =>  [ "PKGWORD PKGNAME;\nour \$VERSION = 'VERSIONSTR';",
                                "PKGWORD PKGNAME;",
                              ],
  'statement_our-literal' =>  [ "PKGWORD PKGNAME;\nour \$VERSION = VERSIONSTR;",
                                "PKGWORD PKGNAME;",
                              ],
  'statement_inline'      =>  [ "PKGWORD PKGNAME VERSIONSTR;",
                                "PKGWORD PKGNAME;",
                              ],
  'block_our'             =>  [ "PKGWORD PKGNAME {\n  our \$VERSION = 'VERSIONSTR';\n  # code!\n}",
                                "PKGWORD PKGNAME {\n  #code!\n}",
                              ],
  'block_our-literal'     =>  [ "PKGWORD PKGNAME {\n  our \$VERSION = VERSIONSTR;\n  # code!\n}",
                                "PKGWORD PKGNAME {\n  #code!\n}",
                              ],
  'block_inline'          =>  [ "PKGWORD PKGNAME VERSIONSTR {\n  # code!\n}",
                                "PKGWORD PKGNAME {\n  #code!\n}",
                              ],
);

my %KNOWN_KEY     = map {; $_ => 1 } qw(pkgword version style);
my %KNOWN_PKGWORD = map {; $_ => 1 } qw(package class role);

sub as_string {
  my ($self) = @_;

  my $layout = $self->_layout;

  my (@unknown) = grep {; ! $KNOWN_KEY{$_} } keys %$layout;
  if (@unknown) {
    Carp::confess("Unknown entries in package layout: @unknown");
  }

  my $layout_pkgword = $layout->{pkgword} // 'package';
  my $layout_version = $layout->{version} // 'our';
  my $layout_style   = $layout->{style}   // 'statement';

  unless ($KNOWN_PKGWORD{$layout_pkgword}) {
    Carp::confess("Invalid value for package layout's pkgword");
  }

  my $version = $self->version;
  my $name    = $self->name;

  my $key = join q{_}, $layout_style, $layout_version;

  my $template_pair = $STYLE_TEMPLATE{$key};
  confess("Can't handle style/version combination in package layout")
    unless $template_pair;

  my $template = $template_pair->[ defined $version ? 0 : 1 ];

  my $body = $template  =~ s/PKGWORD/$layout_pkgword/r
                        =~ s/PKGNAME/$name/r
                        =~ s/VERSIONSTR/$version/r;

  return $body;
}

subtype 'Module::Faker::Type::Packages'
  => as 'ArrayRef[Module::Faker::Package]';

no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Faker::Package - a faked package in a faked module

=head1 VERSION

version 0.026

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
