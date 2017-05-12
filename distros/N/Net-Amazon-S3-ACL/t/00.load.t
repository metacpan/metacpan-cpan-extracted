use Test::More tests => 6;

BEGIN {
   use_ok('Net::Amazon::S3::ACL');
   use_ok('Net::Amazon::S3::ACL::XMLHelper');
   use_ok('Net::Amazon::S3::ACL::Grant');
   use_ok('Net::Amazon::S3::ACL::Grant::Email');
   use_ok('Net::Amazon::S3::ACL::Grant::ID');
   use_ok('Net::Amazon::S3::ACL::Grant::URI');
} ## end BEGIN

diag("Testing Net::Amazon::S3::ACL $Net::Amazon::S3::ACL::VERSION");
