#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 37;

BEGIN {
    use_ok('XML::Simple');
    use_ok('Carp');
    use_ok('Class::Accessor::Grouped');
  	use_ok('XML::OBEXFTP::FolderListing');
}

diag( "Testing XML::OBEXFTP::FolderListing $XML::OBEXFTP::FolderListing::VERSION, Perl $], $^X" );

use XML::OBEXFTP::FolderListing;

my $data = make_data();


my $p = XML::OBEXFTP::FolderListing->new;
isa_ok($p, 'XML::OBEXFTP::FolderListing');
can_ok( $p, qw(folders files parent_folder  tree
                parse is_folder is_file
                info perms size new
                type modified modified_sane));


my $tree = $p->parse($data);
my $dump_tree = make_tree();

is_deeply( $tree, $dump_tree, 'return of ->parse' );
is_deeply( $dump_tree, $p->tree, 'return of ->tree');
is(
    $p->is_folder('audio'),
    1,
    'is_folder("audio") must be true',
);
is(
    $p->is_folder('31-01-08_2213.jpg'),
    0,
    'is_folder("31-01-08_2213.jpg") must be false',
);
is(
    $p->is_file('audio'),
    0,
    'is_file("audio") must be false',
);
is(
    $p->is_file('31-01-08_2213.jpg'),
    1,
    'is_file("31-01-08_2213.jpg") must be true',
);
is(
    $p->perms('31-01-08_2213.jpg'),
    'RW',
    q|->perms('31-01-08_2213.jpg')|,
);
is(
    $p->perms('audio', 'folder'),
    'RW',
    q|->perms('audio', 'folder')|,
);


my @folders = @{ $p->folders };
ok( scalar(grep $_ eq 'audio', @folders), '->folders has `audio`');
ok( scalar(grep $_ eq 'video', @folders), '->folders has `video`');
ok( scalar(grep $_ eq 'picture', @folders), '->folders has `picture`');

my @files = @{ $p->files };
for my $file (
    '26-01-08_1228.jpg',  '05-02-08_2312.jpg',   '26-01-08_0343.jpg',
    '05-02-08_2043.jpg',  '31-01-08_2213.jpg',   '05-02-08_2047.jpg'
) {
    ok( scalar(grep $_ eq $file, @files), '->files has `$file`');
}

is(
    $p->size('31-01-08_2213.jpg'),
    '27665',
    q|->size('31-01-08_2213.jpg')|,
);

is(
    $p->type('26-01-08_1228.jpg'),
    'image/jpeg',
    q|->type('26-01-08_1228.jpg')|,
);

for ( @{ $p->files } ) {
    is(
        $p->type($_),
        'image/jpeg',
        qq|->type('$_')|,
    );
}

is(
    $p->modified('audio','folder'),
    '19700101T000000Z',
    q|->modified('audio','folder')|,
);

is(
    $p->modified('26-01-08_0343.jpg'),
    '20080126T034339Z',
    q|->modified('26-01-08_0343.jpg')|,
);

my $VAR1 = {
          'hour' => '00',
          'minute' => '00',
          'second' => '00',
          'month' => '01',
          'day' => '01',
          'year' => '1970'
        };

is_deeply(
    $p->modified_sane('audio','folder'),
    $VAR1,
    q|->modified_sane('audio','folder')|,
);

$VAR1 = {
          'hour' => '03',
          'minute' => '43',
          'second' => '39',
          'month' => '01',
          'day' => '26',
          'year' => '2008'
        };
is_deeply(
    $p->modified_sane('26-01-08_0343.jpg'),
    $VAR1,
    q|->modified_sane('26-01-08_0343.jpg')|,
);


$VAR1 = {
          'type' => 'image/jpeg',
          'modified_sane' => {
                               'hour' => '03',
                               'minute' => '43',
                               'second' => '39',
                               'month' => '01',
                               'day' => '26',
                               'year' => '2008'
                             },
          'perms' => 'RW',
          'size' => '40802',
          'modified' => '20080126T034339Z'
        };

is_deeply(
    $p->info('26-01-08_0343.jpg'),
    $VAR1,
    q|->info('26-01-08_0343.jpg')|,
);

$VAR1 = {
          'type' => 'folder',
          'modified_sane' => {
                               'hour' => '00',
                               'minute' => '00',
                               'second' => '00',
                               'month' => '01',
                               'day' => '01',
                               'year' => '1970'
                             },
          'perms' => 'RW',
          'size' => '0',
          'modified' => '19700101T000000Z'
        };

is_deeply(
    $p->info('audio','folder'),
    $VAR1,
    q|->info('audio','folder')|,
);

sub make_data {
my $data =<<'END_DATA';
<?xml version="1.0" ?>
<!DOCTYPE folder-listing SYSTEM "obex-folder-listing.dtd">
<folder-listing>
<parent-folder />
<folder name="audio" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
<folder name="video" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
<folder name="picture" size="0" type="folder" modified="19700101T000000Z" user-perm="RW" />
<file name="31-01-08_2213.jpg" size="27665" type="image/jpeg" modified="20080131T221123Z" user-perm="RW" />
<file name="26-01-08_1228.jpg" size="40196" type="image/jpeg" modified="20080126T122836Z" user-perm="RW" />
<file name="05-02-08_2043.jpg" size="33210" type="image/jpeg" modified="20080205T204310Z" user-perm="RW" />
<file name="26-01-08_0343.jpg" size="40802" type="image/jpeg" modified="20080126T034339Z" user-perm="RW" />
<file name="05-02-08_2312.jpg" size="33399" type="image/jpeg" modified="20080205T230946Z" user-perm="RW" />
<file name="05-02-08_2047.jpg" size="21318" type="image/jpeg" modified="20080205T204358Z" user-perm="RW" />
</folder-listing>
END_DATA
}

sub make_tree {
    my $VAR1 = {
          'parent_folder' => {},
          'file' => {
                      '26-01-08_1228.jpg' => {
                                             'type' => 'image/jpeg',
                                             'size' => '40196',
                                             'modified' => '20080126T122836Z',
                                             'user-perm' => 'RW'
                                           },
                      '05-02-08_2312.jpg' => {
                                             'type' => 'image/jpeg',
                                             'size' => '33399',
                                             'modified' => '20080205T230946Z',
                                             'user-perm' => 'RW'
                                           },
                      '26-01-08_0343.jpg' => {
                                             'type' => 'image/jpeg',
                                             'size' => '40802',
                                             'modified' => '20080126T034339Z',
                                             'user-perm' => 'RW'
                                           },
                      '05-02-08_2043.jpg' => {
                                             'type' => 'image/jpeg',
                                             'size' => '33210',
                                             'modified' => '20080205T204310Z',
                                             'user-perm' => 'RW'
                                           },
                      '31-01-08_2213.jpg' => {
                                             'type' => 'image/jpeg',
                                             'size' => '27665',
                                             'modified' => '20080131T221123Z',
                                             'user-perm' => 'RW'
                                           },
                      '05-02-08_2047.jpg' => {
                                             'type' => 'image/jpeg',
                                             'size' => '21318',
                                             'modified' => '20080205T204358Z',
                                             'user-perm' => 'RW'
                                           }
                    },
          'folder' => {
                        'audio' => {
                                   'type' => 'folder',
                                   'size' => '0',
                                   'modified' => '19700101T000000Z',
                                   'user-perm' => 'RW'
                                 },
                        'video' => {
                                   'type' => 'folder',
                                   'size' => '0',
                                   'modified' => '19700101T000000Z',
                                   'user-perm' => 'RW'
                                 },
                        'picture' => {
                                     'type' => 'folder',
                                     'size' => '0',
                                     'modified' => '19700101T000000Z',
                                     'user-perm' => 'RW'
                                   }
                      }
        };
}