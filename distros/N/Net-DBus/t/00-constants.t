# -*- perl -*-
use Test::More tests => 6;
BEGIN { 
	use_ok('Net::DBus::Binding::Watch');
	use_ok('Net::DBus::Binding::Message');
	use_ok('Net::DBus::Binding::Bus');
	 };


my $fail = 0;
foreach my $constname (qw(
        SYSTEM SESSION STARTER)) {
  next if (eval "my \$a = &Net::DBus::Binding::Bus::$constname; 1");
  print "# fail: $@";
  $fail = 1;
}
ok( $fail == 0 , 'Net::DBus::Binding::Bus Constants' );

$fail = 0;
foreach my $constname (qw(
        TYPE_ARRAY TYPE_BOOLEAN
	TYPE_BYTE TYPE_DOUBLE TYPE_STRUCT
        TYPE_INT32 TYPE_INT64 TYPE_DICT_ENTRY
	TYPE_INVALID TYPE_SIGNATURE TYPE_OBJECT_PATH
	TYPE_STRING TYPE_UINT32 TYPE_UINT64)) {
  next if (eval "my \$a = &Net::DBus::Binding::Message::$constname; 1");
  print "# fail: $@";
  $fail = 1;
}
ok( $fail == 0 , 'Net::DBus::Binding::Message Constants' );

$fail = 0;
foreach my $constname (qw(
        READABLE WRITABLE
        ERROR HANGUP)) {
  next if (eval "my \$a = &Net::DBus::Binding::Watch::$constname; 1");
  print "# fail: $@";
  $fail = 1;
}

ok( $fail == 0 , 'Net::DBus::Binding::Watch Constants' );
