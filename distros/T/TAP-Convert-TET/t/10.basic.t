use strict;
use warnings;
use Test::More;
use TAP::Convert::TET;
use TAP::Parser;

my @schedule;

BEGIN {
    my $TIME = qr{\d\d:\d\d:\d\d};
    my $DATE = qr{\d{8}};

    @schedule = (
        {
            name        => 'Simple',
            parser_args => { tap => join( "\n", '1..2', 'ok 1', 'not ok 2' ) },
            expect      => [
                qr{^0\|3\.7a $TIME $DATE\|User: \S+ \(\d+\) TAP::Convert::TET Start$},
                qr{^5\|[^|]*\|System Information$},
                qr{^10\|1 Simple $TIME\|TC Start$},
                qr{^400\|1 1 1 $TIME\|IC Start$},
                qr{^200\|1 1 $TIME\|TP Start$},
                qr{^520\|1 1 000000000 1 1\|ok 1$},
                qr{^220\|1 1 0 $TIME\|PASS$},
                qr{^410\|1 1 1 $TIME\|IC End$},
                qr{^400\|1 2 1 $TIME\|IC Start$},
                qr{^200\|1 2 $TIME\|TP Start$},
                qr{^520\|1 2 000000000 1 1\|not ok 2$},
                qr{^220\|1 2 1 $TIME\|FAIL$},
                qr{^410\|1 2 1 $TIME\|IC End$},
                qr{^80\|1 0 $TIME\|TC End$},
                qr{^900\|$TIME\|TCC End$}
            ],
        },
        {
            name        => 'All TAP syntax',
            parser_args => {
                tap => join( "\n",
                    "TAP version 13",
                    "1..4",
                    "ok 1 - Input file opened",
                    "not ok 2 - First line of the input valid",
                    "  ---",
                    "  message: 'First line invalid'",
                    "  severity: fail",
                    "  data:",
                    "    got: 'Flirble'",
                    "    expect: 'Fnible'",
                    "  ...",
                    "ok 3 - Read the rest of the file",
                    "not ok 4 - Summarized correctly # TODO Not written yet",
                    "  ---",
                    "  message: \"Can't make summary yet\"",
                    "  severity: todo",
                    "  ..." )
            },
            expect => [
                qr{^0\|3\.7a $TIME $DATE\|User: \S+ \(\d+\) TAP::Convert::TET Start$},
                qr{^5\|[^|]*\|System Information$},
                qr{^10\|1 All TAP syntax $TIME\|TC Start$},
                qr{^400\|1 1 1 $TIME\|IC Start$},
                qr{^200\|1 1 $TIME\|TP Start$},
                qr{^520\|1 1 000000000 1 1\|ok 1 - Input file opened$},
                qr{^220\|1 1 0 $TIME\|PASS$},
                qr{^410\|1 1 1 $TIME\|IC End$},
                qr{^400\|1 2 1 $TIME\|IC Start$},
                qr{^200\|1 2 $TIME\|TP Start$},
                qr{^520\|1 2 000000000 1 1\|not ok 2 - First line of the input valid$},
                qr{^220\|1 2 1 $TIME\|FAIL$},
                qr{^410\|1 2 1 $TIME\|IC End$},
                qr{^400\|1 3 1 $TIME\|IC Start$},
                qr{^200\|1 3 $TIME\|TP Start$},
                qr{^520\|1 3 000000000 1 1\|ok 3 - Read the rest of the file$},
                qr{^220\|1 3 0 $TIME\|PASS$},
                qr{^410\|1 3 1 $TIME\|IC End$},
                qr{^400\|1 4 1 $TIME\|IC Start$},
                qr{^200\|1 4 $TIME\|TP Start$},
                qr{^520\|1 4 000000000 1 1\|not ok 4 - Summarized correctly # TODO Not written yet$},
                qr{^220\|1 4 5 $TIME\|UNTESTED$},
                qr{^410\|1 4 1 $TIME\|IC End$},
                qr{^80\|1 0 $TIME\|TC End$},
                qr{^900\|$TIME\|TCC End$},
            ]
        },
    );

    plan tests => @schedule * 4;
}

sub zipper {
    die "Not an array ref" if grep { 'ARRAY' ne ref $_ } @_;
    my @ar = @_;
    return sub {
        return unless grep { @$_ } @ar;
        return map { shift @$_ } @ar;
    };
}

sub output_ok {
    my $name = shift;
    my $iter = zipper( @_ );
    my $ln   = 0;
    my $bad  = 0;
    my @diag = ();

    while ( my ( $got, $want ) = map { $_ || '*** missing ***' } $iter->() ) {
        unless ( $got =~ $want ) {
            push @diag, "Item $ln: \"$got\" doesn't match $want\n";
            $bad++;
        }
        $ln++;
    }

    ok $bad == 0, "$name: results match";
    diag( join( "", @diag ) ) if @diag;
}

for my $test ( @schedule ) {
    my $name = $test->{name};
    ok my $parser = TAP::Parser->new( $test->{parser_args} ),
      "$name: parser created OK";
    my $output = [];
    ok my $converter = TAP::Convert::TET->new( { output => $output } ),
      "$name: converter created OK";
    isa_ok $converter, 'TAP::Convert::TET';

    $converter->start;
    $converter->convert( $parser, $name );
    $converter->end;

    output_ok( $name, $output, $test->{expect} );
}
