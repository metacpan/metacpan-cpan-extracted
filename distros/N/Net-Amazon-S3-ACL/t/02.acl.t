# vim: filetype=perl :
use strict;
use warnings;

use lib 't';
use NAS3Test;

use Test::More tests => 119; # last test to print
use Data::Dumper;

my $module = 'Net::Amazon::S3::ACL';

require_ok($module);

my $xml = NAS3Test::get_sample_acl();

{
   my $acl = $module->new();
   $acl->parse($xml);

   is($acl->owner_id(),          'yadda',    'owner_id');
   is($acl->owner_displayname(), 'whatever', 'owner_displayname');

   ok(my $grants = $acl->grants(), 'grants list exists');

   is(scalar(keys %$grants), 3, 'acl has right number of elements');

   {
      my $by_id = $grants->{yadda};
      ok($by_id, 'yadda is in acl');
      isa_ok($by_id, 'Net::Amazon::S3::ACL::Grant::ID');
      is($by_id->key(), 'yadda', "key is correct");
      is($by_id->ID(),   'yadda', 'id is yadda');
      is($by_id->displayname(), 'whatever', "yadda's display name is correct");
      is($by_id->permissions()->[0], 'FULL_CONTROL', "yadda's permissions");
   }

   {
      my $by_email = $grants->{'foo@example.com'};
      ok($by_email, 'email is in acl');
      isa_ok($by_email, 'Net::Amazon::S3::ACL::Grant::Email');
      is($by_email->key(), 'foo@example.com', "key is correct");
      is($by_email->email(), 'foo@example.com', 'email is correct');
      is($by_email->permissions()->[0], 'READ_ACP', "email's permissions");
   }

   {
      my $by_uri = $grants->{ALL};
      ok($by_uri, 'anonymous is in acl');
      isa_ok($by_uri, 'Net::Amazon::S3::ACL::Grant::URI');
      is($by_uri->key(), 'ALL', "key is correct");
      like($by_uri->URI(), qr{\A http://}mxs, 'anonymous is specified by URI');
      is($by_uri->permissions()->[0], 'READ', "URI's permissions");
   }

   # Delete anonymous
   $acl->delete('*');
   is(keys(%$grants), 2, 'one less key after deletion');
   ok(! scalar(grep { $_ eq 'ALL' } keys %$grants), 'anonymous was deleted');

   $acl->delete('yadda');
   $acl->delete('foo@example.com');
   is(keys(%$grants), 0, 'no more grants in acl');

   # Add new items
   $acl->add(
      foo               => 'READ',
      'bar@example.com' => '*',
      authenticated     => 'W',
      '*' => '*',
   );

   {
      my $by_id = $grants->{foo};
      ok($by_id, 'foo created in acl');
      isa_ok($by_id, 'Net::Amazon::S3::ACL::Grant::ID');
      is($by_id->key(), 'foo', "key is correct");
      is($by_id->ID(),   'foo', 'id is yadda');
      is($by_id->displayname(), undef, "foo's display name is correctly not set");
      is($by_id->permissions()->[0], 'READ', "foo's permissions");
   }

   {
      my $by_email = $grants->{'bar@example.com'};
      ok($by_email, 'email created in acl');
      isa_ok($by_email, 'Net::Amazon::S3::ACL::Grant::Email');
      is($by_email->key(), 'bar@example.com', "key is correct");
      is($by_email->email(), 'bar@example.com', 'email is correct');
      is($by_email->permissions()->[0], 'FULL_CONTROL', "email's permissions");
   }

   {
      my $by_uri = $grants->{ALL};
      ok($by_uri, 'anonymous created in acl');
      isa_ok($by_uri, 'Net::Amazon::S3::ACL::Grant::URI');
      is($by_uri->key(), 'ALL', "key is correct");
      like($by_uri->URI(), qr{\A http:// .* AllUsers}mxs, 'anonymous URI');
      is($by_uri->permissions()->[0], 'FULL_CONTROL', "URI's permissions");
   }

   {
      my $by_uri = $grants->{AUTH};
      ok($by_uri, 'authenticated group created in acl');
      isa_ok($by_uri, 'Net::Amazon::S3::ACL::Grant::URI');
      is($by_uri->key(), 'AUTH', "key is correct");
      like($by_uri->URI(), qr{\A http:// .* AuthenticatedUsers}mxs, 
         'authenticated URI');
      is($by_uri->permissions()->[0], 'WRITE', "URI's permissions");
   }

   {
      my $by_id = Net::Amazon::S3::ACL::Grant::ID->new(
         {
            ID => 'THE-ID',
            displayname => 'the-name',
            permissions => [ qw( read WRITE ) ],
         } 
      );
      isa_ok($by_id, 'Net::Amazon::S3::ACL::Grant::ID');
      $acl->add($by_id);
      ok(exists($acl->grants()->{'THE-ID'}), 'THE-ID has been added');

      is(@{$by_id->permissions()}, 2, 'two permissions in grant');
      $acl->delete($by_id->key() => 'READ');
      ok(exists($acl->grants()->{'THE-ID'}), 'THE-ID still there after one permission has been deleted');
      is(@{$by_id->permissions()}, 1, 'one permission in grant')
         or diag Dumper $by_id;

      $acl->delete($by_id);
      ok(! exists($acl->grants()->{'THE-ID'}), 'THE-ID has been removed');
   }

   my %variants = (
      WRITE => [qw( w write WriTE > )],
      READ => [qw( r read rEAd < )],
      FULL_CONTROL => [qw( f FULL fuLL_COntrol full-conTROL * )],
      WRITE_ACP => [qw( wP write_acp WriTE-acp )],
      READ_ACP => [qw( Rp read-ACp rEAd_acp )],
   );

   while (my ($main, $variants) = each %variants) {
      for my $variant (@$variants) {
         $acl->delete('foo');
         ok(! $grants->{foo}, 'foo deleted');
         $acl->add(foo => $variant);
         ok($grants->{foo}, 'foo re-added');
         is($grants->{foo}->permissions()->[0], $main, "$main permission");
      }
   }

   # Leave it in a predictable state
  $acl->delete('foo');
  ok(! $grants->{foo}, 'foo deleted (last time)');
  $acl->add(foo => 'READ_ACP');
  ok($grants->{foo}, 'foo re-added (last time)');

   my $xml_out = $acl->stringify();
   for my $regex (
      qr/AllUsers/,
      qr/AuthenticatedUsers/,
      qr/foo/,
      qr/bar\@example\.com/,
      qr/>WRITE</,
      qr/>READ_ACP</,
      qr/>FULL_CONTROL</,
   ) {
      like($xml_out, $regex, "$regex");
   }

   can_ok($acl, 'dump');
   ok(my $dumped_out = $acl->dump(), 'dump produced');
}
