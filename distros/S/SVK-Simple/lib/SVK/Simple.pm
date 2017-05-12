package SVK::Simple;
use strict;
use Class::Field qw(field);
use SVK;
use SVK::XD;
use SVK::Util qw(get_anchor catfile catdir);
our $VERSION = '0.03';

field 'output';
field svk => -init => '$self->_load_svk';

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self->svk;
}

sub _load_svk {
    my $self = shift;
    $ENV{HOME} ||= catdir(@ENV{qw( HOMEDRIVE HOMEPATH )});
    my $svkpath = $ENV{SVKROOT} || catfile($ENV{HOME}, ".svk");
    my $xd = SVK::XD->new ( giantlock => "$svkpath/lock",
                            statefile => "$svkpath/config",
                            svkpath => $svkpath,
                           );
    $xd->load;
    if($self->output) {
        return SVK->new(xd => $xd,output => $self->output);
    }
    return SVK->new(xd => $xd);
}

__END__

=head1 NAME

SVK::Simple - Simple SVK object loader

=head1 SYNOPSIS

    my $output;
    my $svk = SVK::Simple->new(output => \$output);

    $svk->ls("//");
    print $output;

=head1 DESCRIPTION

Although SVK.pm itself is already simple enough, there still are some
misc requirements in the svk script which is not included in
SVK.pm. This module helps people who wants to write some SVK
applications. It provides a simple SVK object loader, so people will
not have to handle XD initialization.

=head1 METHODS

=over

=item new(output => SCALAR_REF)

This package provides only one method: C<new()>, it takes an optional
named parameter "output", which should be a scalarref. All the
following SVK command output will be store in to that scalar. Please
always initalized your C<$svk> object as in SYNOPSIS. If "output"
is not given, then all the outputs goes out to STDOUT. What is
returned is an SVK object, you may perform svk commands like this:

    $svk->$cmd($params)

Where C<$cmd> is one of those commands listed in C<svk help commands>.

=back

That's all about this module, enjoy it.

=head1 SEE ALSO

L<SVK>, L<svk>

=head1 COPYRIGHT

Copyright 2005-2007 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut
