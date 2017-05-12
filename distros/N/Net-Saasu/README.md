# NAME

Net::Saasu - Interface to the Saasu online accounting platform!

# VERSION

Version 0.1

# SYNOPSIS

A very basic interface to saasu, an online accounting system
([http://saasu.com](http://saasu.com)). This may morph into a more complete interface
over time but for the moment this basic implementation abstracts
everything we need. Detaild API documentation can be found on the saasu
page ([http://help.saasu.com/api/](http://help.saasu.com/api/)).
    

    my $saasu = Net::Saasu->new(
        key     => 'API KEY',
        file_id => 12345,
        debug   => 1
    );

Example from the saasu docs for a POST request:

    my $hash = {
        tasks => {
            insertTransactionCategory => {
                transactionCategory => {
                    -uid     => 0,
                    type           => 'Income',
                    name           => 'Consulting Fees',
                    isActive       => 'true',
                    ledgerCode     => 'IT001',
                    defaultTaxCode => 'G1',
                }
            } 
        } 
    };

    $saasu->post($hash);
    if ( my $list = $saasu->post( $hash )){
        print Dumper($list);
    }
    else {
        print Dumper($saasu->error);
        $saasu->clear_error;
    }

# SUBROUTINES/METHODS



## get

Call saasu in get mode and pull data. Decodes the data and returns a
nice perl hash. In case of an error the error response is set in
$self->error and we return nothing.
    

    my $params = { IsActive => 1 };
    if(my $result = $saasu->get(Command, $params)){
        # do something with $result
    } else {
        # you got an error in $saasu->error
        # clean it up with 
        $saasu->clear_error;
    }

## post

Push some data to saasu.

## delete

Delete an object in saasu

## \_talk

INTERNAL: Talk to the web service

# AUTHOR

Lenz Gschwendtner, `<norbu09 at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-net-saasu at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Saasu](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Saasu).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.







# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Saasu



You can also look for information at:

- Github Issues: (report bugs here)

    [https://github.com/norbu09/Net-Saasu/issues](https://github.com/norbu09/Net-Saasu/issues)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Net-Saasu](http://annocpan.org/dist/Net-Saasu)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Net-Saasu](http://cpanratings.perl.org/d/Net-Saasu)

- Search CPAN

    [http://search.cpan.org/dist/Net-Saasu/](http://search.cpan.org/dist/Net-Saasu/)



# ACKNOWLEDGEMENTS



# LICENSE AND COPYRIGHT

Copyright 2012 Lenz Gschwendtner.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic\_license\_2\_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


