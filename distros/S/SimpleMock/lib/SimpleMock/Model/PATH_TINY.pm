package SimpleMock::Model::PATH_TINY;
use strict;
use warnings;
use Path::Tiny;

use Data::Dumper;

our $VERSION = '0.01';


# list attributes that can be 0 (false) or 1 (true)
our @t_f_keys = qw(assert exists has_same_bytes);
my %t_f = (0 =>1, 1=>1);

sub validate_mocks {
    my $mocks_data = shift;

    my $new_mocks = {};

    PATH: foreach my $path (keys %$mocks_data) {
        # implicit directory if has children
        $mocks_data->{$path}->{is_dir} =1 if $mocks_data->{$path}->{children};

        T_F_KEY: foreach my $key (@t_f_keys) {
            my $val = $mocks_data->{$path}->{$key};
            next T_F_KEY unless defined $val;
            $t_f{$val} or die "Invalid value for key '$key' in Path::Tiny mock for path '$path' - must be 0|1"; 
        }

        $new_mocks->{PATH_TINY}->{$path} = $mocks_data->{$path};
    }
    return $new_mocks;
}

1;

=head1 NAME

SimpleMock::Model::PATH_TINY

=head1 DESCRIPTION

This module allows you to register mocks for Path::Tiny

=head1 USAGE

You probably won't use this module directly. Instead, you will use the `SimpleMock` module to register your mocks. Here's an example of how to do that:

    use SimpleMock qw(register_mocks);

    register_mocks(
        PATH_TINY => {
            '/path/to/dir/pr/file' => {

                # if data is set, it's implicitly a file, otherwise it's a directory
                data => $file_content,

                # these are all true by default, but you can set to false for them to throw
                # or return false as noted
                assert => 0,              # throws
                exists => 0,              # return 0
                has_same_bytes => 0,      # return 0 - value is hard coded for ALL comparisons on a mock

                # returns this hard coded value for the stat - set as appropriate (obviously fake below)
                stat => [1,2,3,4],

                # digest hash for the mock. Set as appropriate if calling digest()
                digest => '1a2b3c4d536f',
            },
        }
    );

For basic usage, you just need this:

    register_mocks(
        PATH_TINY => {

            # file MUST have a data attribute
            '/path/to/file.txt' => { data => 'file content' },

            # directory must NOT have a data attribute
            '/path/to/dir' => {},
        }
    );

=cut
