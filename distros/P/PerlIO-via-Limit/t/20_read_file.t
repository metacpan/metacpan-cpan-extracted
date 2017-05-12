use strict;
use Test::More tests => 40;
#use Test::More qw/no_plan/;

use PerlIO::via::Limit;
use Exception::Class;

my $file = "t/20_read_file.txt";
my $read;
my $s200 = qq{Perl officially stands for Practical Extraction and Report Language, except when it doesn't.\x0aPerl was originally a language optimized for scanning arbitrary text files, extracting information from tho}; #'

my $layer_via_create = sub {
    my $limit = PerlIO::via::Limit->create(@_);
    "<:via($limit)";
};

my $layer_via_class = sub {
    PerlIO::via::Limit->length(@_);
    "<:via(Limit)";
};


for my $layer ($layer_via_class, $layer_via_create){
    my $contents = '';
    local $/ = undef;

    {
        ok( open( $read, $layer->(undef), $file ), 'open for reading' );
        $contents = <$read>;
        ok( close $read, 'close ok' );
        is( length $contents, -s $file, 'unlimited, read all' );
    }

    {
        open( $read, $layer->((-s $file) * 2), $file ) or die;
        $contents = <$read>;
        close $read or die;
        is( length $contents, -s $file, 'read all less than limit' );
    }

    {
        open( $read, $layer->(200), $file ) or die;
        $contents = <$read>;
        close $read or die;
        is( length $contents, 200, 'limited 200' );
        is( $contents, $s200, 'contents restricted' );
    }

    {
        $contents = '';
        open( $read, $layer->(200), $file ) or die;
        $contents .= $_ while( <$read> );
        close $read or die;
        is( length $contents, 200, 'read limited step by step line' );
        is( $contents, $s200, 'contents has 200 length' );
    }

    {
        $contents = '';
        open( $read, $layer->(200), $file ) or die;
        my $total_size = 0;
        while( my $size = read($read, my $buf, 10) ){ # <--- less limit
            $total_size += $size;
            $contents   .= $buf;
        }
        close $read or die;
        is( length $contents, 200, 'read limited using CORE::read' );
        is( $contents, $s200, 'contents has 200 length' );
        is( $total_size, 200, 'CORE::read returns right value');
    }

    {
        $contents = '';
        open( $read, $layer->(200), $file ) or die;
        my $total_size = 0;
        while( my $size = read($read, my $buf, 200) ){ # <--- just limit
            $total_size += $size;
            $contents   .= $buf;
        }
        close $read or die;
        is( length $contents, 200, 'read limited using CORE::read' );
        is( $contents, $s200, 'contents has 200 length' );
        is( $total_size, 200, 'CORE::read returns right value');
    }

    {
        $contents = '';
        open( $read, $layer->(200), $file ) or die;
        my $total_size = 0;
        while( my $size = read($read, my $buf, 1024) ){ # <--- over limit
            $total_size += $size;
            $contents   .= $buf;
        }
        close $read or die;
        is( length $contents, 200, 'read limited using CORE::read' );
        is( $contents, $s200, 'contents has 200 length' );
        is( $total_size, 200, 'CORE::read returns right value');
    }

} # end of for my $layer


sub test_throwable {
    my $read = shift;

    my $contents = '';
    eval { $contents .= $_ while( <$read> ) };
    my $exception = $@;
    close $read or die;

    ok( ref($exception), "exception is a reference" );
    ok( Exception::Class->caught('PerlIO::via::Limit::Exception'),
                          'caught PerlIO::via::Limit::Exception');

    TODO: {
        local $TODO = "How to do it?";
        is( length $contents, 10, 'caught but it has read restrict length');
    }
}

{
    PerlIO::via::Limit->length(10);
    PerlIO::via::Limit->sensitive(1);
    open( $read, "<:via(Limit)", $file ) or die;
    test_throwable($read);
}

{
    my $limit = PerlIO::via::Limit->create(10);
    $limit->sensitive(1);
    open( $read, "<:via($limit)", $file ) or die;
    test_throwable($read);
}

1;
__END__
