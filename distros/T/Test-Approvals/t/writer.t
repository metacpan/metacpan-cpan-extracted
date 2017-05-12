#! perl

use strict;
use warnings FATAL => qw(all);
use autodie;
use version; our $VERSION = qv('v0.0.5');

use Perl6::Slurp;
use Test::Approvals::Specs qw(describe it run_tests);
use Test::Approvals::Writers::TextWriter;
use Test::More;

describe 'A TextWriter', sub {
    my $w = Test::Approvals::Writers::TextWriter->new( result => 'Hello' );
    it 'Writes the contents to a file', sub {
        my ($spec) = @_;
        $w->write_to('out.txt');

        my $written = slurp('out.txt');
        unlink 'out.txt';
        is $written, 'Hello', $spec;
    };

    it 'Writes the contents to a handle', sub {
        my ($spec) = @_;
        my $out_buf;
        open my $out, '>', \$out_buf;
        $w->print_to($out);
        close $out;
        is $out_buf, 'Hello', $spec;
    };

    it 'Stores the result type', sub {
        my ($spec) = @_;
        is $w->file_extension, 'txt', $spec;
    };

    it 'Lets the caller choose the result type', sub {
        my ($spec) = @_;
        my $x = Test::Approvals::Writers::TextWriter->new(
            result         => 'Hello',
            file_extension => 'html'
        );
        is $x->file_extension, 'html', $spec;
    };

    it 'Handles NULL' => sub {
        my ($spec) = @_;
        my $x = Test::Approvals::Writers::TextWriter->new( result => undef );

        my $out_buf;
        open my $out, '>', \$out_buf;
        $x->print_to($out);
        $out->close;
        is $out_buf, undef, $spec;
      }
};

run_tests();
