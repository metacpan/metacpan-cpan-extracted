#!/usr/bin/env perl

use v5.38;

use strict;
use warnings;

use JSON::PP;

package Local::ConstantsPodParser {

    use parent 'Pod::Simple';

    use feature 'postderef', 'signatures';
    use experimental 'builtin';
    use builtin::compat 'trim', 'true', 'false';

    sub new ( $class ) {

        my $self = $class->SUPER::new();
        $self->{constants} = {};
        $self->reset;
        return $self;
    }

    sub reset ( $self ) {
        $self->{in_docs_section}   = false;
        $self->{current_category} = undef;
        $self->{stack}            = [];
    }

    sub _handle_element_start ( $self, $name, $ = undef ) {

        $DB::single = $self->{in_docs_section};
        if ( $name =~ /over-(.*)/ ) {
            push $self->{stack}->@*, $1;
        }
        else {
            $self->{_text} = q{};
        }
    }

    sub _handle_element_end ( $self, $name, $ = undef ) {

        if ( $name =~ /over-(.*)/ ) {
            $self->{stack}[-1] eq $1
              or die( "unbalanced $1" );
            pop $self->{stack}->@*;
        }

        elsif ( $name eq 'item-text' ) {

            return
                 unless $self->{in_docs_section}
              && $self->{stack}->@* == 1;

            my $title = uc trim( delete $self->{_text} // q{} ) =~ s/ /_/gr;
            return if !$title || $title eq q{*};

            $self->{constants}{$title} //= [];
            $self->{current_category} = $self->{constants}{$title};
        }

        elsif ( $name eq 'Para' ) {
            delete $self->{_text};
            return;
        }

        elsif ( $name eq 'head1' ) {
            my $heading = trim( delete $self->{_text} // q{} );

            $self->{in_docs_section} = $heading eq 'CONSTANTS';
            $self->reset unless $self->{in_docs_section};
        }

        elsif ( $name eq 'Verbatim' ) {
            return
                 unless $self->{in_docs_section}
              && $self->{stack}->@* == 1
              && $self->{current_category};

            my $text      = delete $self->{_text} // q{};
            my @constants = grep { length }
              map { trim( $_ ) } split /\s+/, $text;

            push $self->{current_category}->@*, @constants;
        }
    }

    sub _handle_text ( $self, $text, @ ) {
        $self->{_text} .= $text if exists $self->{_text};
    }

    sub constants ( $self ) {
        return $self->{constants};
    }
}

my $input  = shift @ARGV // 'lib/PGPLOTx/Constants.pm';
my $output = shift @ARGV // 't/constants.json';

my $parser = Local::ConstantsPodParser->new();
$parser->parse_file( $input );

keys $parser->constants->%*
  or die( 'no constants found?' );

open my $out_fh, '>', $output or die "Cannot open '$output' for writing: $!";
print {$out_fh} JSON::PP->new->pretty->canonical->encode( $parser->constants );
close $out_fh or die "Cannot close '$output': $!";
