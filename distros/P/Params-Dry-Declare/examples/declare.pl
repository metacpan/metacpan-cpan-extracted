#!/usr/bin/env perl
#*
#* Name: example.pl
#* Info: just an example of syntax
#* Author: Pawel Guspiel (neo77) <merlin@panth-net.com>
#*
package ParamsTest;

no strict;
use warnings;

our $VERSION = 1.0;

#=------------------------------------------------------------------------( use, constants )

# --- find bin ---
use FindBin qw/$Bin/;
use lib $Bin."/../lib";

use Params::Dry::Declare;
# --- cpan libs ---

use Data::Dumper;



#=------------------------------------------------------------------------( typedef definitions )

typedef 'name', 'String[20]|Int';

#=------------------------------------------------------------------------( functions )

    sub new (
                ! name:;                                    --- name of the user
                ? second_name   : name      = 'unknown';    --- second name
                ? details       : String    = 'yakusa';     --- details
            ) {

    return bless {
                    name        => $p_name,
                    second_name => $p_second_name,
                    details     => $p_details,
                }, 'ParamsTest';
    }

    sub get_name (
                ! first : Bool = 1; --- this is using default type for required parameter name without default value
        ) {

        return +($p_first) ? $self->{'name'} : $self->{'second_name'};
    }



    sub print_message (
                ! name: = $self->get_name;      --- name of the user
                ! text: String|Int = 1;             --- message text

        ) {
        print "For: $p_name\n\nText:\n$p_text\n\n";
    }

    sub gret (;) {
        print Dumper($self);
        return "For: \n\nText:\n";
    }

    sub print_messages (
                ! name: = $self->get_name;      --- name of the user
                ! text: String = 1;             --- message text

        ) {
        print "For: $p_name\n\nText:\n$p_text\n\n";
    }

#=------------------------------------------------------------------------( main )

    # how is it working
    my $pawel = new(name => 'Pawel', details => 'bzebeze');
    my $lucja = new(name => 'Lucja', second_name => 'Marta');

    print "Message for Gabriela / explicte set in function\n";
    $pawel->print_message( name => 'Gabriela', text => 'Some message for you has arrived');
    print "Message for Pawel / taken from object\n";
    $pawel->print_message( text => 'Some message for you has arrived');
    print "Text is on place because when using declare  no_more is added automaticly\n";

    # no parameters
    print $pawel->gret;

    # get effective type
    typedef 'super_name', 'name';
    print Params::Dry::__get_effective_type('super_name');





