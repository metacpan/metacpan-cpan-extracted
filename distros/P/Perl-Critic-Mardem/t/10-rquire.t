#!perl

use utf8;

use 5.010;

use strict;
use warnings;

our $VERSION = '0.05';

use Test2::V0;
use Test2::Tools::Exception qw/lives/;

plan 'tests' => 10;

ok( lives {
        require Perl::Critic::Mardem;
    }
);

ok( lives {
        require Perl::Critic::Mardem::Util;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitBlockComplexity;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitConditionComplexity;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitFileSize;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitLargeBlock;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitLargeFile;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitLargeSub;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitManyConditionsInSub;
    }
);

ok( lives {
        require Perl::Critic::Policy::Mardem::ProhibitReturnBooleanAsInt;
    }
);

done_testing();

__END__

#-----------------------------------------------------------------------------

=pod

=encoding utf8

=head1 NAME

00-rquire.t

=head1 DESCRIPTION

Test-Script

=head1 AFFILIATION

This policy is part of L<Perl::Critic::Mardem>.

=head1 AUTHOR

Markus Demml, mardem@cpan.com

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2024, Markus Demml

This library is free software; you can redistribute it and/or modify it 
under the same terms as the Perl 5 programming language system itself. 
The full text of this license can be found in the LICENSE file included
with this module.

=cut
