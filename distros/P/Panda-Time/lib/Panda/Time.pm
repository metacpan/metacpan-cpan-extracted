package Panda::Time;
use parent 'Panda::Export';
use 5.012;
use Panda::Lib;
use Panda::Install::Payload;

our $VERSION = '3.1.2';

require Panda::XSLoader;
Panda::XSLoader::bootstrap('Panda::Time', $VERSION);

__init__();

sub __init__ {
    use_embed_zones() unless tzsysdir(); # use embed zones by default where system zones are unavailable
}

sub use_system_zones {
    if (tzsysdir()) {
        tzdir(undef);
    } else {
        warn("Panda::Time[use_system_zones]: this OS has no olson timezone files, you cant use system zones");
    }
}

sub use_embed_zones {
    my $dir = Panda::Install::Payload::payload_dir('Panda::Time');
    return tzdir("$dir/zoneinfo");
}

sub available_zones {
    my $zones_dir = tzdir() or return;
    return _scan_zones($zones_dir, '');
}

sub _scan_zones {
    my ($root, $subdir) = @_;
    my $dir = $subdir ? "$root/$subdir" : $root;
    my @list;
    opendir my $dh, $dir or die "Panda::Time[available_zones]: cannot open $dir: $!";
    while (my $entry = readdir $dh) {
        my $first = substr($entry, 0, 1);
        next if $first eq '.' or $first eq '_';
        my $path = "$dir/$entry";
        if (-d $path) {
            push @list, _scan_zones($root, $subdir ? "$subdir/$entry" : $entry);
        } elsif (-f $path) {
            open my $fh, '<', $path or die "Panda::Time[available_zones]: cannot open $path: $!";
            my $content = readline $fh;
            next unless $content =~ /^TZif/;
            next if $entry =~ /(posixrules|Factory)/;
            push @list, $subdir ? "$subdir/$entry" : $entry;
            close $fh;
        }
    }
    closedir $dh;
    
    return @list;
}
 
1;
