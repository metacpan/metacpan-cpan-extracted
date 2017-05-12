###########################################
package PasswordMonkey::Bouncer;
###########################################
use strict;
use warnings;

PasswordMonkey::make_accessor( __PACKAGE__, $_ ) for qw(
name
expect
);

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        expect => undef,
        %options,
    };

    bless $self, $class;
}

###########################################
sub check {
###########################################
    my($self) = @_;

    die "'check' needs to be overridden by the bouncer plugin class";
}

1;

__END__

=head1 NAME

PasswordMonkey::Bouncer - Bouncer Base Class

=head1 SYNOPSIS

    use PasswordMonkey::Bouncer;

=head1 DESCRIPTION

PasswordMonkey bouncer base class. Don't use directly, but let your
bouncer plugins inherit from it.

=head1 AUTHOR

2011, Mike Schilli <cpan@perlmeister.com>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2011 Yahoo! Inc. All rights reserved. The copyrights to 
the contents of this file are licensed under the Perl Artistic License 
(ver. 15 Aug 1997).

