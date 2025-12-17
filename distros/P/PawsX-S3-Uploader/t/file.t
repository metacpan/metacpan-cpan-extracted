use Test2::V0;
use Path::Tiny 0.011;
use lib 't/lib';
use TestingPaws;
use BadHandle;
use builtin::compat 0.003003 qw(true false);
use PawsX::S3::Uploader;

subtest 'from fh, put_object' => sub {
    my ($s3, $mock_object) = TestingPaws::build_test_paws();

    my @events;
    my $uploader = PawsX::S3::Uploader->new(
        s3       => $s3,
        bucket   => 'testbucket',
        key      => 'testkey',
        callback => sub { push @events, [@_] },
    );

    my $this_file = path(__FILE__);
    my $fh = $this_file->openr_raw;
    my $output = $uploader->upload_fh($fh);

    ok eof($fh), 'file should have reached EOF';

    is \@events, [
        [ add        => { size => $this_file->size } ],
        [ put_object => { size => $this_file->size } ],
        [ finish     => { output => $output } ],
    ], 'should upload in a single call';
};

subtest 'from fh, multipart' => sub {
    my ($s3, $mock_object) = TestingPaws::build_test_paws();

    my $this_file = path(__FILE__);
    my $part_size = int($this_file->size / 2) - 10;
    my $last_part_size = $this_file->size - ($part_size*2);

    my @events;
    my $uploader = PawsX::S3::Uploader->new(
        s3       => $s3,
        bucket   => 'testbucket',
        key      => 'testkey',
        always_multipart => true,
        _under_testing => true,
        min_part_size => $part_size,
        callback => sub { push @events, [@_] },
    );

    my $fh = $this_file->openr_raw;
    my $output = $uploader->upload_fh($fh);

    ok eof($fh), 'file should have reached EOF';

    is \@events, [
        [ add             => { size => $part_size } ],
        [ start_multipart => { upload_id => 'testing' } ],
        [ upload_part     => { size => $part_size, part_number => 1 } ],

        [ add         => { size => $part_size } ],
        [ upload_part => { size => $part_size, part_number => 2 } ],

        [ add         => { size => $last_part_size } ],
        [ upload_part => { size => $last_part_size, part_number => 3 } ],

        [ complete_multipart => { } ],

        [ finish => { output => $output } ],
    ], 'should upload in a single call';
};

subtest 'from fh, error handling' => sub {
    my ($s3, $mock_object) = TestingPaws::build_test_paws();

    my @events;
    my $uploader = PawsX::S3::Uploader->new(
        s3       => $s3,
        bucket   => 'testbucket',
        key      => 'testkey',
        callback => sub { push @events, [@_] },
        _under_testing => true,
        min_part_size => 1000,
    );

    my $fh = \do { no warnings 'once'; local *HANDLE };
    tie *$fh, 'BadHandle', 1010, 1;

    like(
        dies { $uploader->upload_fh($fh) },
        qr{sysread failed},
        'filehandle errors should be propagated',
    );

    is \@events, [
        [ add             => { size => 1010 } ],
        [ start_multipart => { upload_id => 'testing' } ],
        [ upload_part     => { size => 1010, part_number => 1 } ],
        [ abort_multipart => { error => D() } ],
    ], 'multipart should abort';
};

done_testing;
