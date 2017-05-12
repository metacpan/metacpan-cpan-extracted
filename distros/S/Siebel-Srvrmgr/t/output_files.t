use warnings;
use strict;
use File::Spec;
use Siebel::Srvrmgr::ListParser;
use Cwd;
use Test::More;
use Set::Tiny 0.04;
use Scalar::Util qw(blessed);

my ($files_ref,$current_gen) = fixtures();
my $tests     = 0;

# calculating the number of tests to be executed
foreach my $item ( @{$files_ref} ) {
    $tests += scalar( @{ $item->{expected} } ) + 6;
}

plan tests => $tests;

foreach my $item ( @{$files_ref} ) {
    note( 'Testing file ' . $item->{filename} . ' at ' . $item->{location});
    my $missing = $current_gen->difference( $item->{outputs} );
    if ( $missing->size > 0 ) {
        diag(
"This is a regression test, there are missing valid outputs in this file:\n",
            join( "\n", ( $missing->members ) )
        );
    }
    my $data_ref =
      read_data( File::Spec->catfile( $item->{location}, $item->{filename} ) );
    my $parser;

    if ( $item->{location} =~ /delimited/ ) {
        $parser =
          Siebel::Srvrmgr::ListParser->new( { field_delimiter => '|' } );
    }
    else {
        $parser = Siebel::Srvrmgr::ListParser->new();
    }

    $parser->parse($data_ref);
    my $res    = $parser->get_parsed_tree();
    my $got    = scalar( @{$res} );
    my $expect = scalar( @{ $item->{expected} } );
    is( $got, $expect, 'the expected number of parsed objects is returned' );
    isa_ok( $parser->get_enterprise(),
        'Siebel::Srvrmgr::ListParser::Output::Enterprise' );
    is( $parser->get_enterprise()->get_version(),
        $item->{version}, 'enterprise attribute has the correct version' );
    is( $parser->get_enterprise()->get_patch(),
        $item->{patch}, 'enterprise attribute has the correct patch number' );
    is( $parser->get_enterprise()->get_total_servers(),
        $item->{servers},
        'enterprise attribute returns the correct number of servers' );
    is(
        $parser->get_enterprise()->get_total_servers(),
        $parser->get_enterprise()->get_total_conn(),
'enterprise attribute has the correct number of servers and connected servers'
    );

  SKIP: {
        skip 'number of parsed objects must be equal to the expected', $expect
          unless ( $got == $expect );

        for ( my $i = 0 ; $i < $expect ; $i++ ) {
            is(
                ref( $res->[$i] ),
                $item->{expected}->[$i],
                'the object returned is a ' . $item->{expected}->[$i]
            );
        }
    }
}

sub read_data {
    my $path = shift;
    open( my $in, '<', $path ) or die "Cannot read $path: $!\n";
    my @data;

    while (<$in>) {
        s/\015?\012$/\012/o;    #setting EOL to a sane value
        chomp();
        push( @data, $_ );
    }

    close($in);
    return \@data;
}

sub fixtures {

    my @first_gen = (
        'Siebel::Srvrmgr::ListParser::Output::LoadPreferences',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompTypes',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks',
    );
    my $first_gen  = Set::Tiny->new(@first_gen);
    my @second_gen = (
        'Siebel::Srvrmgr::ListParser::Output::LoadPreferences',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompTypes',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions',
    );
    my $second_gen  = Set::Tiny->new(@second_gen);
    my @current_gen = (
        'Siebel::Srvrmgr::ListParser::Output::LoadPreferences',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListComp',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompTypes',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListParams',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListCompDef',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListTasks',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListServers',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions',
        'Siebel::Srvrmgr::ListParser::Output::Tabular::ListSessions',
    );
    my $current_gen = Set::Tiny->new(@current_gen);
    my $fixed_dir = File::Spec->catdir( getcwd(), 't', 'output', 'fixed' );
    my $delim_dir = File::Spec->catdir( getcwd(), 't', 'output', 'delimited' );
    my @files     = (
        {
            filename => '8.1.1.5_21229.txt',
            location => $fixed_dir,
            version  => '8.1.1.5',
            patch    => 21229,
            servers  => 4,
            expected => \@first_gen,
            outputs  => $first_gen
        },
        {
            filename => '8.0.0.2_20412.txt',
            location => $fixed_dir,
            version  => '8.0.0.2',
            patch    => 20412,
            servers  => 1,
            expected => \@first_gen,
            outputs  => $first_gen
        },
        {
            filename => '8.0.0.2_20412.txt',
            location => $delim_dir,
            version  => '8.0.0.2',
            patch    => 20412,
            servers  => 1,
            expected => \@first_gen,
            outputs  => $first_gen
        },
        {
            filename => '8.1.1.7_21238.txt',
            location => $delim_dir,
            version  => '8.1.1.7',
            patch    => 21238,
            servers  => 3,
            expected => \@second_gen,
            outputs  => $second_gen
        },
        {
            filename => '8.1.1.14_23044.txt',
            location => $fixed_dir,
            version  => '8.1.1.14',
            patch    => 23044,
            servers  => 1,
            expected => \@second_gen,
            outputs  => $second_gen
        },
        {
            filename => '8.1.1.7_21238.txt',
            location => $fixed_dir,
            version  => '8.1.1.7',
            patch    => 21238,
            servers  => 3,
            expected => \@second_gen,
            outputs  => $second_gen
        },
        {
            filename => '8.1.1.11_23030.txt',
            location => $fixed_dir,
            version  => '8.1.1.11',
            patch    => 23030,
            servers  => 12,
            expected => \@current_gen,
            outputs  => $current_gen
        },
        {
            filename => '8.1.1.11_23030.txt',
            location => $delim_dir,
            version  => '8.1.1.11',
            patch    => 23030,
            servers  => 12,
            expected => \@current_gen,
            outputs  => $current_gen
        },

    );

    return \@files, $current_gen;

}
