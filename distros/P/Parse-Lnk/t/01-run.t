use strict;
use warnings;
use Test::More;
use Parse::Lnk qw(parse_lnk resolve_lnk);
use File::Spec;

my @dirs = File::Spec->splitdir(__FILE__);
pop @dirs;
my $samples_dir_path = File::Spec->catdir(@dirs, 'lnk_samples');

my $data = {
    'shortcut_1.lnk' => {
        attributes         => ["DIRECTORY TARGET"],
        base_path          => "C:\\Windows",
        create_time        => '1575709424.539',
        flags              => [
            "HAS SHELLIDLIST",
            "POINTS TO FILE/DIR",
            "NO DESCRIPTION",
            "NO RELATIVE PATH STRING",
            "HAS WORKING DIRECTORY",
            "NO CMD LINE ARGS",
            "NO CUSTOM ICON",
        ],
        guid               => "0114020000000000c000000000000046",
        hot_key            => 0,
        icon_index         => 0,
        last_accessed_time => '1619239760.195',
        modified_time      => '1618939654.518',
        remaining_path     => "",
        show_wnd           => 1,
        show_wnd_flag      => "SW_NORMAL",
        target_length      => 16384,
        target_type        => "local",
        volume_label       => "Workstation",
        volume_serial      => "84e01896",
        volume_type        => "Fixed (Hard Disk)",
        working_directory  => "D:\\etc",
    },
    'shortcut_2.lnk' => {
        attributes         => ["ARCHIVE"],
        base_path          => "C:\\Windows\\notepad.exe",
        create_time        => '1610525895.046',
        flags              => [
            "HAS SHELLIDLIST",
            "POINTS TO FILE/DIR",
            "NO DESCRIPTION",
            "NO RELATIVE PATH STRING",
            "HAS WORKING DIRECTORY",
            "NO CMD LINE ARGS",
            "NO CUSTOM ICON",
        ],
        guid               => "0114020000000000c000000000000046",
        hot_key            => 0,
        icon_index         => 0,
        last_accessed_time => '1619457749.031',
        modified_time      => '1610525895.050',
        remaining_path     => "",
        show_wnd           => 1,
        show_wnd_flag      => "SW_NORMAL",
        target_length      => 202240,
        target_type        => "local",
        volume_label       => "Workstation",
        volume_serial      => "84e01896",
        volume_type        => "Fixed (Hard Disk)",
        working_directory  => "C:\\Windows",
    },
    'shortcut_3.lnk' => {
        attributes         => ["HIDDEN TARGET", "SYSTEM FILE TARGET", "DIRECTORY TARGET"],
        base_path          => "\\\\WS1\\G\$",
        create_time        => '1610249161.817',
        flags              => [
            "NO SHELLIDLIST",
            "POINTS TO FILE/DIR",
            "NO DESCRIPTION",
            "NO RELATIVE PATH STRING",
            "NO WORKING DIRECTORY",
            "NO CMD LINE ARGS",
            "NO CUSTOM ICON",
        ],
        guid               => "0114020000000000c000000000000046",
        hot_key            => 0,
        icon_index         => 0,
        last_accessed_time => '1619486909.151',
        modified_time      => '1619481114.034',
        remaining_path     => undef,
        show_wnd           => 1,
        show_wnd_flag      => "SW_NORMAL",
        target_length      => 16384,
        target_type        => "network",
    },
    'shortcut_4.lnk' => {
        attributes         => ["DIRECTORY TARGET"],
        base_path          => "\\\\WS1\\KOQ",
        create_time        => '1610257078.135',
        flags              => [
            "NO SHELLIDLIST",
            "POINTS TO FILE/DIR",
            "NO DESCRIPTION",
            "NO RELATIVE PATH STRING",
            "NO WORKING DIRECTORY",
            "NO CMD LINE ARGS",
            "NO CUSTOM ICON",
        ],
        guid               => "0114020000000000c000000000000046",
        hot_key            => 0,
        icon_index         => 0,
        last_accessed_time => '1617683200.690',
        modified_time      => '1538255194.282',
        remaining_path     => undef,
        show_wnd           => 1,
        show_wnd_flag      => "SW_NORMAL",
        target_length      => 49152,
        target_type        => "network",
    },
    'shortcut_5.lnk' => {
        attributes         => ["DIRECTORY TARGET"],
        base_path          => "\\\\10.114.42.131\\fzarabozo",
        create_time        => '1619319912.013',
        flags              => [
            "HAS SHELLIDLIST",
            "POINTS TO FILE/DIR",
            "NO DESCRIPTION",
            "NO RELATIVE PATH STRING",
            "NO WORKING DIRECTORY",
            "NO CMD LINE ARGS",
            "NO CUSTOM ICON",
        ],
        guid               => "0114020000000000c000000000000046",
        hot_key            => 0,
        icon_index         => 0,
        last_accessed_time => '1619495386.048',
        mapped_drive       => "W:",
        modified_time      => '1619319912.013',
        remaining_path     => "",
        show_wnd           => 1,
        show_wnd_flag      => "SW_NORMAL",
        target_length      => 0,
        target_type        => "network",
    },
    'empty.lnk' => { # This is an empty file
        error => 'Invalid Lnk file header',
    },
    'invalid_1.lnk' => { # This is a text file
        error => 'Invalid Lnk file header',
    },
    'invalid_2.lnk' => { # This is a jpg image
        error => 'Invalid Lnk file header',
    },
    'invalid_3.lnk' => { # This is a folder
        error => 'Not a file',
    },
    'invalid_4.lnk' => { # Not existent one
        error => 'Not a file',
    },
};

plan tests => 5 * keys %$data;

for my $sample_name (sort keys %$data) {
    eval {
        my $filename = File::Spec->catfile($samples_dir_path, $sample_name);
        
        my $parse_pkg = Parse::Lnk->from($filename);
        is_deeply $parse_pkg, (exists $data->{$sample_name}->{error} ? undef : $data->{$sample_name}), "Parse::Lnk->from('$filename') returns the expected data";
        
        my $parse_lnk = parse_lnk $filename;
        is_deeply $parse_lnk, (exists $data->{$sample_name}->{error} ? undef : $data->{$sample_name}), "parse_lnk('$filename') returns the expected data";
        
        my $resolve_lnk = resolve_lnk $filename;
        is $resolve_lnk, (exists $data->{$sample_name}->{error} ? undef : $data->{$sample_name}->{base_path}), "resolve_lnk('$filename') returns the expected data";
        
        my $lnk = Parse::Lnk->new(filename => $filename);
        my $r = $lnk->parse;
        is_deeply $r, (exists $data->{$sample_name}->{error} ? undef : $data->{$sample_name}), "\$lnk->parse with '$filename' set returns the expected data";
        is_deeply $lnk, $data->{$sample_name}, "\$lnk afeter \$lnk->parse with $filename has the right keys and data";
    };
    if (my $e = $@) {
        print STDERR "Error while testing: $e\n";
        exit 255;
    }
}

