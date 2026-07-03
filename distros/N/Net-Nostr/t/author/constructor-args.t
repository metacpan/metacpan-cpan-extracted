#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;
use File::Find qw(find);

subtest 'named argument normalization is the only constructor arg pattern' => sub {
    my @files = _module_files();

    my @violations;
    for my $file (sort @files) {
        my $source = _slurp($file);

        push @violations, "$file uses bless { \@_ }" if $source =~ /bless\s+\{\s*\@_\s*\}/;
        push @violations, "$file uses my %args = \@_" if $source =~ /my\s+%args\s*=\s*\@_/;
        push @violations, "$file destructures %args directly" if $source =~ /my\s+\([^)]*%args[^)]*\)\s*=\s*\@_/;
        push @violations, "$file destructures (%args) directly" if $source =~ /my\s+\(%args\)\s*=\s*\@_/;
        push @violations, "$file references public ConstructorArgs"
            if $source =~ /Net::Nostr::ConstructorArgs\b/;
    }

    is(\@violations, [], 'constructors and named-arg methods use the shared normalizer');
};

subtest 'constructor arg normalizer is internal only' => sub {
    ok(-e 'lib/Net/Nostr/_ConstructorArgs.pm', 'internal helper module exists');
    ok(!-e 'lib/Net/Nostr/ConstructorArgs.pm', 'public helper module does not exist');
};

subtest 'constructor POD documents accepted argument forms' => sub {
    my @checks;

    for my $file (sort _module_files()) {
        my $source = _slurp($file);

        push @checks, [$file, 'new']
            if $source =~ /^=head2 new$/m;
        while ($source =~ /^=head2 (new_\w+)$/mg) {
            push @checks, [$file, $1];
        }
    }

    push @checks, (
        ['lib/Net/Nostr/RemoteSigning.pm', 'BunkerConnection'],
        ['lib/Net/Nostr/RemoteSigning.pm', 'NostrConnect'],
        ['lib/Net/Nostr/RemoteSigning.pm', 'Nip05Metadata'],
        ['lib/Net/Nostr/RemoteSigning.pm', 'Discovery'],
        ['lib/Net/Nostr/RemoteSigning.pm', 'Request'],
        ['lib/Net/Nostr/RemoteSigning.pm', 'Response'],
        ['lib/Net/Nostr/WalletConnect.pm', 'Connection'],
        ['lib/Net/Nostr/WalletConnect.pm', 'Info'],
        ['lib/Net/Nostr/WalletConnect.pm', 'Response'],
        ['lib/Net/Nostr/WalletConnect.pm', 'Notification'],
    );

    my @violations;
    for my $check (@checks) {
        my ($file, $heading) = @$check;
        my $source = _slurp($file);

        my ($section) = $source =~ /^=head2 \Q$heading\E\n(.*?)(?=^=head[12]\b|\z)/ms;
        push @violations, "$file POD missing =head2 $heading" unless defined $section;
        next unless defined $section;

        push @violations, "$file =head2 $heading does not document flat list/hashref arguments"
            unless $section =~ /flat list or a single hash\s+reference/;
    }

    is(\@violations, [], 'constructor POD documents flat list and hashref forms');
};

done_testing;

sub _module_files {
    my @files;
    find(
        sub {
            return unless -f $_ && /\.pm\z/;
            push @files, $File::Find::name;
        },
        'lib',
    );
    return @files;
}

sub _slurp {
    my ($file) = @_;
    open my $fh, '<', $file or die "open $file: $!";
    my $source = do { local $/; <$fh> };
    close $fh;
    return $source;
}
