# -*- perl -*-
BEGIN
{
    use strict;
    use warnings;

    use Test::More qw( no_plan );

    # use Nice::Try debug => 5, debug_file => './dev/debug.pl';
    use Nice::Try;
};

my $i = 0;
$i += 2;
is( $i, 2, 'Done parsing' );

done_testing;

__END__

=encoding utf8

=head1 NAME

MyTest - Some fake module

=head1 SYNOPSIS

    package MyModule;
    BEGIN
    {
        use strict;
        use Module::Generic;
        our( @ISA ) = qw( Module::Generic );
    };

=head1 VERSION

    v0.1

=head1 DESCRIPTION

    Checking if I cn confuse the parser

=cut


