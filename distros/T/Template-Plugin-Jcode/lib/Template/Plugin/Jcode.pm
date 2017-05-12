package Template::Plugin::Jcode;

use strict;
use base qw(Template::Plugin);
use Template::Plugin;
use Template::Stash;
use Jcode;
use vars qw($VERSION $AUTOLOAD);
$VERSION = '0.02';

$Template::Stash::SCALAR_OPS->{ jcode } = sub {
    my $str = shift;
    return Template::Plugin::Jcode->new($str);
};

sub new {
    my($class, $str) = @_;
    bless { string => $str }, $class;
}

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    my $jcode = Jcode->new($self->{string});
    return $self->_throw("no such Jcode method: $method")
	unless UNIVERSAL::can($jcode, $method);
    return $jcode->$method(@_);
}

sub _throw {
    my $self = shift;
    die Template::Exception->new('jcode', join(', ', @_));
}

1;
__END__

=head1 NAME

Template::Plugin::Jcode - TT plugin using Jcode methods as virtual method

=head1 SYNOPSIS

  [% USE Jcode %]

  # Convert some string to japanese euc.
  [% foo = 'some string' %]
  [% foo.jcode.euc %]

  # It can use with other virtual methods.
  [% bar = '012-345-678' %]
  [% bar.split('-').0.jcode.tr(from, to) %]

=head1 DESCRIPTION

Template::Plugin::Jcode is plugin for TT, which can use Jcode methods
as virtual method.

=head1 AUTHOR

Yoshiki KURIHARA E<lt>kurihara@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>, L<Jcode>

=cut
