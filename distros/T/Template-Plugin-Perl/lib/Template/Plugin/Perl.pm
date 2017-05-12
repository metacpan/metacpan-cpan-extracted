package Template::Plugin::Perl;

use strict;
use warnings;

use Data::Dumper;
use Template::Plugin;
use base qw( Template::Plugin );
use vars qw( $AUTOLOAD $VERSION );

$VERSION = '0.06';

$Data::Dumper::Indent = 0;
*throw = \&Template::Plugin::Perl::throw;

sub new {
    my ($class, $context, $params) = @_;
    bless {
	    _context => $context,
    }, $class;
}

my $entered = 0;

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    #warn "$method";

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    #warn "\@_ = @_\n";
    if ($entered == 1) {
        die("$method not found\n");
    }
    my @args;
    foreach my $arg (@_) {
        my $code = Data::Dumper->Dump([$arg], ['args']);
        $code =~ s/^\s*\$args\s*=\s*(.*);\s*$/$1/s;
        $code =~ s/^\[(.*)\]\s*$/$1/s;
        push @args, $code;
    }
    my $code = "$method(".join(',', @args).")";
    #warn "code: $code\n";
    $entered = 1;
    my @retval = eval $code;
    $entered = 0;
    if ($@) {
        $self->throw("Perl built-in function error: $@");
    }
    if (!@retval) { return (); }
    if (@retval == 1) { $retval[0] }
    else { \@retval };
}

sub throw {
    my $self = shift;
    die (Template::Exception->new('Plugin Perl', join(', ', @_)));
}

sub pow {
    shift;
    return $_[0] ** $_[1];
}

1;
__END__

=head1 NAME

Template::Plugin::Perl - TT2 plugin to import Perl built-in functions

=head1 VERSION

This document describes Template::Plugin::Perl 0.06 released on 12 March, 2007.

=head1 SYNOPSIS

  [% USE Perl %]

  [% Perl.log(100) %]
  [% Perl.rand(1) %]
  [% Perl.exp(2) %]
  [% Perl.sprintf("%.0f", 3.5) %]
  [% Perl.pow(2, 3) %]   # 2 ** 3;
  [% Perl.eval('2**3') %]
  [% Perl.sin(3.14) %]
  [% Perl.cos(0) %]

  [% Perl.join(',', 'a', 'b', 'c') %]
  [% list = ['a','b','c'];
     Perl.join(',' list) %]

=head1 DESCRIPTION

As a TT programmer, I found it quite inflexible to use the Template Toolkit's
presentation language Language due to the very limited vocabulary. So I wrote 
this little plugin in order to open a window for the template file to the full
richness of most Perl built-in functions, making the Template language a 
"programming language" in a much more serious sense.

As I writing this stuff, The Template language does not support exponential
operator (**). So I add an extra function 'pow' to support this missing
feature. However, there is no doubt that we could treat "Perl.eval" as a
good workaround, just as the L</SYNOPSIS> demonstrates.

According to the current implementation, don't use the functions for real 
@ARRAYs, such as B<shift>, B<pop>. They won't function at all. However,
C<sort>, C<join>, and C<reverse> are notable exceptions. Moreover, 
Arguments of all Perl.* functions are passed by values, and returned in 
scalar context, so some functions for list data, like B<map> and B<grep>, 
make little sense in this context.

builtins that modify their arguments won't work either, such as C<chomp>, C<chop>, and C<pos>.

Please keep in mind I just used AUTOLOAD, eval, and Data::Dumper to do the
magic here.

If you're looking for even more functions, I suggest you take a look at the
L<Template::Plugin::POSIX> module which exports the excellent POSIX repertoire.

=head1 METHODS

=over

=item new

Constructor called by the TT2 template system

=item throw

TT2 exception handling procedure.

=item pow

Non-Perl builtin added for ease of use

=back

=head1 TODO

=over

=item *

Add more unit tests

=back

=head1 SOURCE CONTROL

You can always get the latest version of the source code from
the follow Subversion repository:

L<http://svn.openfoundry.org/ttperl>

There is anonymous access to all.

If you'd like a commit bit, please let me know :)

=head1 AUTHOR

Agent Zhang, E<lt>agentzh@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005, 2006, 2007 by Agent Zhang. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template>,
L<Template::Plugin::POSIX>,
L<Data::Dumper>

=cut

