package Net::StackExchange::Types;
BEGIN {
  $Net::StackExchange::Types::VERSION = '0.102740';
}

# ABSTRACT: Custom types

use Moose::Util::TypeConstraints;
use JSON;

subtype 'List::id'
    => as 'Str'
    => where { $_ =~ /^(?:\d;?)+$/ };

subtype 'JSON::XS::Boolean'
    => as 'JSON::XS::Boolean';

subtype 'JSON::PP::Boolean'
    => as 'JSON::PP::Boolean';

subtype 'Boolean'
    => as 'Str'
    => where { $_ eq 'true' || $_ eq 'false' };

coerce 'Boolean'
    => from 'JSON::XS::Boolean'
    => via {
        if ( JSON::is_bool($_) && $_ == JSON::true ) {
            return 'true';
        }
        return 'false';
    }
    => from 'JSON::PP::Boolean'
    => via {
        if ( JSON::is_bool($_) && $_ == JSON::true ) {
            return 'true';
        }
        return 'false';
    }
    => from 'Int'
    => via {
        if ($_) {
            return 'true';
        }
        return 'false';
    };

no Moose::Util::TypeConstraints;

1;

__END__
=pod

=head1 NAME

Net::StackExchange::Types - Custom types

=head1 VERSION

version 0.102740

=head1 AUTHOR

Alan Haggai Alavi <alanhaggai@alanhaggai.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alan Haggai Alavi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

