##----------------------------------------------------------------------------
## Meta CPAN API - ~/lib/Net/API/CPAN/Exception.pm
## Version v0.1.0
## Copyright(c) 2023 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2023/07/26
## Modified 2023/07/26
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::CPAN::Exception;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Exception );
    our $VERSION = 'v0.1.0';
};

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

Net::API::CPAN::Exception - Meta CPAN API Exception

=head1 SYNOPSIS

    use Net::API::CPAN::Exception;
    my $this = Net::API::CPAN::Exception->new(
        code => 500,
        message => $error_message,
    );
    die( $this );

    my $ex = Net::API::CPAN::Exception->new({
       code => 404,
       type => $error_type,
       file => '/home/joe/some/lib/Net/API/CPAN/Author.pm',
       line => 114,
       message => 'Invalid property provided',
       package => 'Net::API::CPAN::Author',
       subroutine => 'cpanid',
       # Some optional discretionary metadata hash reference
       cause =>
           {
           object => $some_object,
           payload => $json_data,
           },
    });
    print( "Error stack trace: ", $ex->stack_trace, "\n" );
    # or
    $author->updated( $bad_datetime ) || 
        die( "Error in file ", $author->error->file, " at line ", $author->error->line, "\n" );
    # or simply:
    $author->customer_orders || 
        die( "Error: ", $author->error, "\n" );
    $ex->cause->payload;

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class inherits all its methods from L<Module::Generic::Exception>

=head1 METHODS

Plese see L<Module::Generic::Exception> for details.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2023 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
