package Template::Plugin::POSIX;

use strict;
use warnings;

use POSIX ();
use Data::Dumper;
use Template::Plugin;
use base qw( Template::Plugin );
use vars qw( $AUTOLOAD $VERSION );

our $VERSION = '0.05';

$Data::Dumper::Indent = 0;
*throw = \&Template::Plugin::POSIX::throw;

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
    my $code = "POSIX::$method(".join(',', @args).")";
    #warn "code: $code\n";
    $entered = 1;
    my @retval = eval $code;
    $entered = 0;
    if ($@) {
        $self->throw("POSIX function error: $@");
    }
    if (!@retval) { return (); }
    if (@retval == 1) { $retval[0] }
    else { \@retval };
}

sub throw {
    my $self = shift;
    die (Template::Exception->new('Plugin POSIX', join(', ', @_)));
}

1;
__END__

=head1 NAME

Template::Plugin::POSIX - TT2 plugin to import POSIX functions

=head1 VERSION

This document describes Template::Plugin::POSIX 0.05 released on 12 March, 2007.

=head1 SYNOPSIS

  [% USE POSIX %]

  [% POSIX.log(100) %]
  [% POSIX.rand(1) %]
  [% POSIX.exp(2) %]
  [% POSIX.sprintf("%.0f", 3.5) %]
  [% POSIX.pow(2, 3) %]
  [% POSIX.ceil(3.8) %]
  [% POSIX.floor(3.8) %]
  [% POSIX.sin(3.14) %]
  [% POSIX.cos(0) %]

=head1 DESCRIPTION

As a TT programmer, I found it quite inflexible to use the Template Toolkit's
presentation language Language due to the very limited vocabulary. So I wrote
this little plugin in order to open a window for the template file to the full
richness of most POSIX functions, making the Template language a
"programming language" in a much more serious sense.

Please keep in mind I just used AUTOLOAD, eval, and L<Data::Dumper> to do the
magic here.

If you're looking for even more functions, I suggest you take a look at the
L<Template::Plugin::Perl> module which exports the excellent POSIX repertoire.

=head1 METHODS

=over

=item C<new>

Constructor called by the TT2 template system

=item C<throw>

TT2 exception handling procedure.

=back

=head1 TODO

=over

=item *

Add more unit tests.

=back

=head1 SOURCE CONTROL

You can always get the latest version of the source code from
the follow Subversion repository:

L<http://svn.openfoundry.org/ttposix>

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
L<Template::Plugin::Perl>,
L<Data::Dumper>

=cut

