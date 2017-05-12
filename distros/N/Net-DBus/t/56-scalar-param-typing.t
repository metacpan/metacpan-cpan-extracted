# -*- perl -*-

use Test::More tests => 382;

use Carp qw(confess);
$SIG{__DIE__} = sub { confess $_[0] };
use strict;
use warnings;

BEGIN { 
    use_ok('Net::DBus::Binding::Introspector') or die;
    use_ok('Net::DBus::Object') or die;
    use_ok('Net::DBus::Test::MockObject') or die;
    use_ok("Net::DBus", qw(:typing)) or die;
};

TEST_NO_INTROSPECT: {
    my ($bus, $object, $robject, $myobject, $otherobject) = &setup;
    
    ##### String tests
    
    $myobject->ScalarString("Foo");
    is($object->get_last_message_signature, "s", "string as string");
    is($object->get_last_message_param, "Foo", "string as string");

    $myobject->ScalarString(2);
    is($object->get_last_message->get_signature, "s", "int as string");
    is($object->get_last_message_param, "2", "int as string");

    $myobject->ScalarString(5.234);
    is($object->get_last_message->get_signature, "s", "double as string");
    is($object->get_last_message_param, "5.234", "double as string");
    

    #### INT 16 tests

    # Positive integers
    $myobject->ScalarInt16("2");
    is($object->get_last_message_signature, "s", "string as int16");
    is($object->get_last_message_param, "2", "string as int16");

    $myobject->ScalarInt16(2);
    is($object->get_last_message_signature, "s", "int as int16");
    is($object->get_last_message_param, "2", "int as int16");

    $myobject->ScalarInt16(2.0);
    is($object->get_last_message_signature, "s", "double as int16");
    is($object->get_last_message_param, "2", "double as int16");

    # Negative integers
    $myobject->ScalarInt16("-2");
    is($object->get_last_message_signature, "s", "-ve string as int16");
    is($object->get_last_message_param, "-2", "-ve string as int16");

    $myobject->ScalarInt16(-2);
    is($object->get_last_message_signature, "s", "-ve int as int16");
    is($object->get_last_message_param, "-2", "-ve int as int16");

    $myobject->ScalarInt16(-2.0);
    is($object->get_last_message_signature, "s",  "-ve double as int16");
    is($object->get_last_message_param, "-2", "-ve double as int16");

    # Rounding of doubles
    $myobject->ScalarInt16(2.1);
    is($object->get_last_message_signature, "s",  "round down double as int16");
    is($object->get_last_message_param, "2.1", "round down double as int16");

    $myobject->ScalarInt16(2.9);
    is($object->get_last_message_signature, "s",  "round up double as int16");
    is($object->get_last_message_param, "2.9", "round up double as int16");

    $myobject->ScalarInt16(2.5);
    is($object->get_last_message_signature, "s",  "round up double threshold as int16");
    is($object->get_last_message_param, "2.5", "round up double threshold as int16");

    $myobject->ScalarInt16(-2.1);
    is($object->get_last_message_signature, "s",  "-ve round up double as int16");
    is($object->get_last_message_param, "-2.1", "-ve round up double as int16");
        
    $myobject->ScalarInt16(-2.9);
    is($object->get_last_message_signature, "s",  "-ve round down double as int16");
    is($object->get_last_message_param, "-2.9", "-ve round down double as int16");

    $myobject->ScalarInt16(-2.5);
    is($object->get_last_message_signature, "s",  "-ve round down double threshold as int16");
    is($object->get_last_message_param, "-2.5", "-ve round down double threshold as int16");
    

    #### UINT 16 tests

    # Positive integers
    $myobject->ScalarUInt16("2");
    is($object->get_last_message_signature, "s", "string as uint16");
    is($object->get_last_message_param, "2", "string as uint16");

    $myobject->ScalarUInt16(2);
    is($object->get_last_message_signature, "s", "int as uint16");
    is($object->get_last_message_param, "2", "int as uint16");

    $myobject->ScalarUInt16(2.0);
    is($object->get_last_message_signature, "s", "double as uint16");
    is($object->get_last_message_param, "2", "double as uint16");

    # Negative integers
    $myobject->ScalarUInt16("-2");
    is($object->get_last_message_signature, "s", "-ve string as uint16");
    is($object->get_last_message_param, "-2", "-ve string as uint16");

    $myobject->ScalarUInt16(-2);
    is($object->get_last_message_signature, "s", "-ve int as uint16");
    is($object->get_last_message_param, "-2", "-ve int as uint16");

    $myobject->ScalarUInt16(-2.0);
    is($object->get_last_message_signature, "s", "-ve double as uint16");
    is($object->get_last_message_param, "-2", "-ve double as uint16");


    # Rounding of doubles
    $myobject->ScalarUInt16(2.1);
    is($object->get_last_message_signature, "s", "round down double as uint16");
    is($object->get_last_message_param, "2.1", "round down double as uint16");

    $myobject->ScalarUInt16(2.9);
    is($object->get_last_message_signature, "s", "round up double as uint16");
    is($object->get_last_message_param, "2.9", "round up double as uint16");

    $myobject->ScalarUInt16(2.5);
    is($object->get_last_message_signature, "s", "round up double threshold as uint16");
    is($object->get_last_message_param, "2.5", "round up double threshold as uint16");

    
    #### INT 32 tests

    # Positive integers
    $myobject->ScalarInt32("2");
    is($object->get_last_message_signature, "s", "string as int32");
    is($object->get_last_message_param, "2", "string as int32");

    $myobject->ScalarInt32(2);
    is($object->get_last_message_signature, "s", "int as int32");
    is($object->get_last_message_param, "2", "int as int32");

    $myobject->ScalarInt32(2.0);
    is($object->get_last_message_signature, "s", "double as int32");
    is($object->get_last_message_param, "2", "double as int32");

    # Negative integers
    $myobject->ScalarInt32("-2");
    is($object->get_last_message_signature, "s", "-ve string as int32");
    is($object->get_last_message_param, "-2", "-ve string as int32");

    $myobject->ScalarInt32(-2);
    is($object->get_last_message_signature, "s", "-ve int as int32");
    is($object->get_last_message_param, "-2", "-ve int as int32");

    $myobject->ScalarInt32(-2.0);
    is($object->get_last_message_signature, "s",  "-ve double as int32");
    is($object->get_last_message_param, "-2", "-ve double as int32");

    # Rounding of doubles
    $myobject->ScalarInt32(2.1);
    is($object->get_last_message_signature, "s",  "round down double as int32");
    is($object->get_last_message_param, "2.1", "round down double as int32");

    $myobject->ScalarInt32(2.9);
    is($object->get_last_message_signature, "s",  "round up double as int32");
    is($object->get_last_message_param, "2.9", "round up double as int32");

    $myobject->ScalarInt32(2.5);
    is($object->get_last_message_signature, "s",  "round up double threshold as int32");
    is($object->get_last_message_param, "2.5", "round up double threshold as int32");

    $myobject->ScalarInt32(-2.1);
    is($object->get_last_message_signature, "s",  "-ve round up double as int32");
    is($object->get_last_message_param, "-2.1", "-ve round up double as int32");
        
    $myobject->ScalarInt32(-2.9);
    is($object->get_last_message_signature, "s",  "-ve round down double as int32");
    is($object->get_last_message_param, "-2.9", "-ve round down double as int32");

    $myobject->ScalarInt32(-2.5);
    is($object->get_last_message_signature, "s",  "-ve round down double threshold as int32");
    is($object->get_last_message_param, "-2.5", "-ve round down double threshold as int32");
    

    #### UINT 32 tests

    # Positive integers
    $myobject->ScalarUInt32("2");
    is($object->get_last_message_signature, "s", "string as uint32");
    is($object->get_last_message_param, "2", "string as uint32");

    $myobject->ScalarUInt32(2);
    is($object->get_last_message_signature, "s", "int as uint32");
    is($object->get_last_message_param, "2", "int as uint32");

    $myobject->ScalarUInt32(2.0);
    is($object->get_last_message_signature, "s", "double as uint32");
    is($object->get_last_message_param, "2", "double as uint32");

    # Negative integers
    $myobject->ScalarUInt32("-2");
    is($object->get_last_message_signature, "s", "-ve string as uint32");
    is($object->get_last_message_param, "-2", "-ve string as uint32");

    $myobject->ScalarUInt32(-2);
    is($object->get_last_message_signature, "s", "-ve int as uint32");
    is($object->get_last_message_param, "-2", "-ve int as uint32");

    $myobject->ScalarUInt32(-2.0);
    is($object->get_last_message_signature, "s", "-ve double as uint32");
    is($object->get_last_message_param, "-2", "-ve double as uint32");


    # Rounding of doubles
    $myobject->ScalarUInt32(2.1);
    is($object->get_last_message_signature, "s", "round down double as uint32");
    is($object->get_last_message_param, "2.1", "round down double as uint32");

    $myobject->ScalarUInt32(2.9);
    is($object->get_last_message_signature, "s", "round up double as uint32");
    is($object->get_last_message_param, "2.9", "round up double as uint32");

    $myobject->ScalarUInt32(2.5);
    is($object->get_last_message_signature, "s", "round up double threshold as uint32");
    is($object->get_last_message_param, "2.5", "round up double threshold as uint32");

    
    #### Double tests
    
    # Double
    $myobject->ScalarDouble(5.234);
    is($object->get_last_message_signature, "s", "double as double");
    is($object->get_last_message_param, "5.234", "double as double");

    # Stringized Double
    $myobject->ScalarDouble("2.1");
    is($object->get_last_message_signature, "s", "string as double");
    is($object->get_last_message_param, "2.1", "string as double");

    # Integer -> double conversion
    $myobject->ScalarDouble(2);
    is($object->get_last_message_signature, "s", "int as double");
    is($object->get_last_message_param, "2", "int as double");

    
    # -ve Double
    $myobject->ScalarDouble(-5.234);    
    is($object->get_last_message_signature, "s", "-ve double as double");
    is($object->get_last_message_param, "-5.234", "-ve double as double");

    # -ve Stringized Double
    $myobject->ScalarDouble("-2.1");
    is($object->get_last_message_signature, "s", "-ve string as double");
    is($object->get_last_message_param, "-2.1", "-ve string as double");

    # -ve Integer -> double conversion
    $myobject->ScalarDouble(-2);
    is($object->get_last_message_signature, "s", "-ve int as double");
    is($object->get_last_message_param, "-2", "-ve int as double");


    #### Byte tests
    
    # Int
    $myobject->ScalarByte(7);
    is($object->get_last_message_signature, "s", "int as byte");
    is($object->get_last_message_param, "7", "int as byte");

    # Double roudning
    $myobject->ScalarByte(2.6);
    is($object->get_last_message_signature, "s", "double as byte");
    is($object->get_last_message_param, "2.6", "double as byte");

    # Range overflow
    $myobject->ScalarByte(10000);
    is($object->get_last_message_signature, "s", "int as byte overflow");
    is($object->get_last_message_param, "10000", "int as byte overflow");

    
    # -ve Int
    $myobject->ScalarByte(-7);
    is($object->get_last_message_signature, "s", "-ve int as byte");
    is($object->get_last_message_param, "-7", "-ve int as byte");

    # -ve Double roudning
    $myobject->ScalarByte(-2.6);
    is($object->get_last_message_signature, "s", "double as byte");
    is($object->get_last_message_param, "-2.6", "double as byte");

    # -ve Range overflow
    $myobject->ScalarByte(-10000);
    is($object->get_last_message_signature, "s", "-ve int as byte overflow");
    is($object->get_last_message_param, "-10000", "-ve int as byte overflow");
    
    
    ##### Boolean 
    
    # String, O and false
    $myobject->ScalarBoolean("0");
    is($object->get_last_message_signature, "s", "string as boolean, 0 and false");
    is($object->get_last_message_param, "0", "string as boolean, 0 and false");

    # String, O but true
    $myobject->ScalarBoolean("0true");
    is($object->get_last_message_signature, "s", "string as boolean, 0 but true");
    is($object->get_last_message_param, "0true", "string as boolean, 0 but true");

    # String, 1 and true
    $myobject->ScalarBoolean("1true");
    is($object->get_last_message_signature, "s", "string as boolean, 1 and true");
    is($object->get_last_message_param, "1true", "string as boolean, 1 and true");

    # Int true
    $myobject->ScalarBoolean(1);
    is($object->get_last_message_signature, "s", "int as boolean, true");
    is($object->get_last_message_param, "1", "int as boolean, true");

    # Int false
    $myobject->ScalarBoolean(0);
    is($object->get_last_message_signature, "s", "int as boolean, false");
    is($object->get_last_message_param, "0", "int as boolean, false");

    # Undefined and false
    $myobject->ScalarBoolean(undef);
    is($object->get_last_message_signature, "s", "undefined as boolean, false");
    is($object->get_last_message_param, "", "undefined as boolean, false");
    
}



TEST_MANUAL_TYPING: {
    my ($bus, $object, $robject, $myobject, $otherobject) = &setup;
    
    ##### String tests
    
    $myobject->ScalarString("Foo");
    is($object->get_last_message_signature, "s", "string as string");
    is($object->get_last_message_param, "Foo", "string as string");

    $myobject->ScalarString(2);
    is($object->get_last_message->get_signature, "s", "int as string");
    is($object->get_last_message_param, "2", "int as string");

    $myobject->ScalarString(5.234);
    is($object->get_last_message->get_signature, "s", "double as string");
    is($object->get_last_message_param, "5.234", "double as string");
    

    #### INT 16 tests

    # Positive integers
    $myobject->ScalarInt16(dbus_int16("2"));
    is($object->get_last_message_signature, "n", "string as int16");
    is($object->get_last_message_param, 2, "string as int16");

    $myobject->ScalarInt16(dbus_int16(2));
    is($object->get_last_message_signature, "n", "int as int16");
    is($object->get_last_message_param, 2, "int as int16");

    $myobject->ScalarInt16(dbus_int16(2.0));
    is($object->get_last_message_signature, "n", "double as int16");
    is($object->get_last_message_param, 2, "double as int16");

    # Negative integers
    $myobject->ScalarInt16(dbus_int16("-2"));
    is($object->get_last_message_signature, "n", "-ve string as int16");
    is($object->get_last_message_param, -2, "-ve string as int16");

    $myobject->ScalarInt16(dbus_int16(-2));
    is($object->get_last_message_signature, "n", "-ve int as int16");
    is($object->get_last_message_param, -2, "-ve int as int16");

    $myobject->ScalarInt16(dbus_int16(-2.0));
    is($object->get_last_message_signature, "n",  "-ve double as int16");
    is($object->get_last_message_param, -2, "-ve double as int16");

    # Rounding of doubles
    $myobject->ScalarInt16(dbus_int16(2.1));
    is($object->get_last_message_signature, "n",  "round down double as int16");
    is($object->get_last_message_param, 2, "round down double as int16");

    $myobject->ScalarInt16(dbus_int16(2.9));
    is($object->get_last_message_signature, "n",  "round up double as int16");
  SKIP: {
      skip "rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double as int16");
  }
    $myobject->ScalarInt16(dbus_int16(2.5));
    is($object->get_last_message_signature, "n",  "round up double threshold as int16");
  SKIP: {
      skip "rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double threshold as int16");
  }

    $myobject->ScalarInt16(dbus_int16(-2.1));
    is($object->get_last_message_signature, "n",  "-ve round up double as int16");
    is($object->get_last_message_param, -2, "-ve round up double as int16");
        
    $myobject->ScalarInt16(dbus_int16(-2.9));
    is($object->get_last_message_signature, "n",  "-ve round down double as int16");
  SKIP: {
      skip "rounding actually truncates", 1;
      is($object->get_last_message_param, -3, "-ve round down double as int16");
  }

    $myobject->ScalarInt16(dbus_int16(-2.5));
    is($object->get_last_message_signature, "n",  "-ve round down double threshold as int16");
    is($object->get_last_message_param, -2, "-ve round down double threshold as int16");
    

    #### UINT 16 tests

    # Positive integers
    $myobject->ScalarUInt16(dbus_uint16("2"));
    is($object->get_last_message_signature, "q", "string as uint16");
    is($object->get_last_message_param, 2, "string as uint16");

    $myobject->ScalarUInt16(dbus_uint16(2));
    is($object->get_last_message_signature, "q", "int as uint16");
    is($object->get_last_message_param, 2, "int as uint16");

    $myobject->ScalarUInt16(dbus_uint16(2.0));
    is($object->get_last_message_signature, "q", "double as uint16");
    is($object->get_last_message_param, 2, "double as uint16");

    # Negative integers
    $myobject->ScalarUInt16(dbus_uint16("-2"));
    is($object->get_last_message_signature, "q", "-ve string as uint16");
  SKIP: {
      skip "sign truncation is wrong", 1;
      is($object->get_last_message_param, -2, "-ve string as uint16");
  }

    $myobject->ScalarUInt16(dbus_uint16(-2));
    is($object->get_last_message_signature, "q", "-ve int as uint16");
  SKIP: {
      skip "sign truncation is wrong", 1;
      is($object->get_last_message_param, -2, "-ve int as uint16");
  }

    $myobject->ScalarUInt16(dbus_uint16(-2.0));
    is($object->get_last_message_signature, "q", "-ve double as uint16");
  SKIP: {
      skip "sign truncation is wrong", 1;
      is($object->get_last_message_param, -2, "-ve double as uint16");
  }

    # Rounding of doubles
    $myobject->ScalarUInt16(dbus_uint16(2.1));
    is($object->get_last_message_signature, "q", "round down double as uint16");
    is($object->get_last_message_param, 2, "round down double as uint16");

    $myobject->ScalarUInt16(dbus_uint16(2.9));
    is($object->get_last_message_signature, "q", "round up double as uint16");
  SKIP: {
      skip "rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double as uint16");
  }

    $myobject->ScalarUInt16(dbus_uint16(2.5));
    is($object->get_last_message_signature, "q", "round up double threshold as uint16");
  SKIP: {
      skip "rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double threshold as uint16");
  }
    
    #### INT 32 tests

    # Positive integers
    $myobject->ScalarInt32(dbus_int32("2"));
    is($object->get_last_message_signature, "i", "string as int32");
    is($object->get_last_message_param, 2, "string as int32");

    $myobject->ScalarInt32(dbus_int32(2));
    is($object->get_last_message_signature, "i", "int as int32");
    is($object->get_last_message_param, 2, "int as int32");

    $myobject->ScalarInt32(dbus_int32(2.0));
    is($object->get_last_message_signature, "i", "double as int32");
    is($object->get_last_message_param, 2, "double as int32");

    # Negative integers
    $myobject->ScalarInt32(dbus_int32("-2"));
    is($object->get_last_message_signature, "i", "-ve string as int32");
    is($object->get_last_message_param, -2, "-ve string as int32");

    $myobject->ScalarInt32(dbus_int32(-2));
    is($object->get_last_message_signature, "i", "-ve int as int32");
    is($object->get_last_message_param, -2, "-ve int as int32");

    $myobject->ScalarInt32(dbus_int32(-2.0));
    is($object->get_last_message_signature, "i",  "-ve double as int32");
    is($object->get_last_message_param, -2, "-ve double as int32");

    # Rounding of doubles
    $myobject->ScalarInt32(dbus_int32(2.1));
    is($object->get_last_message_signature, "i",  "round down double as int32");
    is($object->get_last_message_param, 2, "round down double as int32");

    $myobject->ScalarInt32(dbus_int32(2.9));
    is($object->get_last_message_signature, "i",  "round up double as int32");
  SKIP: {
      skip "rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double as int32");
  }
    $myobject->ScalarInt32(dbus_int32(2.5));
    is($object->get_last_message_signature, "i",  "round up double threshold as int32");
  SKIP: {
      skip "rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double threshold as int32");
  }

    $myobject->ScalarInt32(dbus_int32(-2.1));
    is($object->get_last_message_signature, "i",  "-ve round up double as int32");
    is($object->get_last_message_param, -2, "-ve round up double as int32");
        
    $myobject->ScalarInt32(dbus_int32(-2.9));
    is($object->get_last_message_signature, "i",  "-ve round down double as int32");
  SKIP: {
      skip "rounding actually truncates", 1;
      is($object->get_last_message_param, -3, "-ve round down double as int32");
  }

    $myobject->ScalarInt32(dbus_int32(-2.5));
    is($object->get_last_message_signature, "i",  "-ve round down double threshold as int32");
    is($object->get_last_message_param, -2, "-ve round down double threshold as int32");
    

    #### UINT 32 tests

    # Positive integers
    $myobject->ScalarUInt32(dbus_uint32("2"));
    is($object->get_last_message_signature, "u", "string as uint32");
    is($object->get_last_message_param, 2, "string as uint32");

    $myobject->ScalarUInt32(dbus_uint32(2));
    is($object->get_last_message_signature, "u", "int as uint32");
    is($object->get_last_message_param, 2, "int as uint32");

    $myobject->ScalarUInt32(dbus_uint32(2.0));
    is($object->get_last_message_signature, "u", "double as uint32");
    is($object->get_last_message_param, 2, "double as uint32");

    # Negative integers
    $myobject->ScalarUInt32(dbus_uint32("-2"));
    is($object->get_last_message_signature, "u", "-ve string as uint32");
  SKIP: {
      skip "sign truncation is wrong", 1;
      is($object->get_last_message_param, -2, "-ve string as uint32");
  }

    $myobject->ScalarUInt32(dbus_uint32(-2));
    is($object->get_last_message_signature, "u", "-ve int as uint32");
  SKIP: {
      skip "sign truncation is wrong", 1;
      is($object->get_last_message_param, -2, "-ve int as uint32");
  }

    $myobject->ScalarUInt32(dbus_uint32(-2.0));
    is($object->get_last_message_signature, "u", "-ve double as uint32");
  SKIP: {
      skip "sign truncation is wrong", 1;
      is($object->get_last_message_param, -2, "-ve double as uint32");
  }

    # Rounding of doubles
    $myobject->ScalarUInt32(dbus_uint32(2.1));
    is($object->get_last_message_signature, "u", "round down double as uint32");
    is($object->get_last_message_param, 2, "round down double as uint32");

    $myobject->ScalarUInt32(dbus_uint32(2.9));
    is($object->get_last_message_signature, "u", "round up double as uint32");
  SKIP: {
      skip "rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double as uint32");
  }

    $myobject->ScalarUInt32(dbus_uint32(2.5));
    is($object->get_last_message_signature, "u", "round up double threshold as uint32");
  SKIP: {
      skip "rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double threshold as uint32");
  }
    
    #### Double tests
    
    # Double
    $myobject->ScalarDouble(dbus_double(5.234));
    is($object->get_last_message_signature, "d", "double as double");
    is($object->get_last_message_param, 5.234, "double as double");

    # Stringized Double
    $myobject->ScalarDouble(dbus_double("2.1"));
    is($object->get_last_message_signature, "d", "string as double");
    is($object->get_last_message_param, 2.1, "string as double");

    # Integer -> double conversion
    $myobject->ScalarDouble(dbus_double(2));
    is($object->get_last_message_signature, "d", "int as double");
    is($object->get_last_message_param, 2.0, "int as double");

    
    # -ve Double
    $myobject->ScalarDouble(dbus_double(-5.234));
    is($object->get_last_message_signature, "d", "-ve double as double");
    is($object->get_last_message_param, -5.234, "-ve double as double");

    # -ve Stringized Double
    $myobject->ScalarDouble(dbus_double("-2.1"));
    is($object->get_last_message_signature, "d", "-ve string as double");
    is($object->get_last_message_param, -2.1, "-ve string as double");

    # -ve Integer -> double conversion
    $myobject->ScalarDouble(dbus_double(-2));
    is($object->get_last_message_signature, "d", "-ve int as double");
    is($object->get_last_message_param, -2.0, "-ve int as double");


    #### Byte tests
    
    # Int
    $myobject->ScalarByte(dbus_byte(7));
    is($object->get_last_message_signature, "y", "int as byte");
    is($object->get_last_message_param, 7, "int as byte");

    # Double roudning
    $myobject->ScalarByte(dbus_byte(2.6));
    is($object->get_last_message_signature, "y", "double as byte");
  SKIP: {
      skip "rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "double as byte");
  }

    # Range overflow
    $myobject->ScalarByte(dbus_byte(10000));
    is($object->get_last_message_signature, "y", "int as byte overflow");
  SKIP: {
      skip "rounding actually truncates", 1;
      is($object->get_last_message_param, 10000, "int as byte overflow");
  }
    
    # -ve Int
    $myobject->ScalarByte(dbus_byte(-7));
    is($object->get_last_message_signature, "y", "-ve int as byte");
  SKIP: {
      skip "sign truncation broken", 1;
      is($object->get_last_message_param, -7, "-ve int as byte");
  }

    # -ve Double roudning
    $myobject->ScalarByte(dbus_byte(-2.6));
    is($object->get_last_message_signature, "y", "double as byte");
  SKIP: {
      skip "sign truncation broken", 1;
      is($object->get_last_message_param, -3, "double as byte");
  }

    # -ve Range overflow
    $myobject->ScalarByte(dbus_byte(-10000));
    is($object->get_last_message_signature, "y", "-ve int as byte overflow");
  SKIP: {
      skip "sign truncation broken", 1;
      is($object->get_last_message_param, -10000, "-ve int as byte overflow");
  }
    
    ##### Boolean 
    
    # String, O and false
    $myobject->ScalarBoolean(dbus_boolean("0"));
    is($object->get_last_message_signature, "b", "string as boolean, 0 and false");
    is($object->get_last_message_param, '', "string as boolean, 0 and false");

    # String, O but true
    $myobject->ScalarBoolean(dbus_boolean("0true"));
    is($object->get_last_message_signature, "b", "string as boolean, 0 but true");
    is($object->get_last_message_param, '1', "string as boolean, 0 but true");

    # String, 1 and true
    $myobject->ScalarBoolean(dbus_boolean("1true"));
    is($object->get_last_message_signature, "b", "string as boolean, 1 and true");
    is($object->get_last_message_param, '1', "string as boolean, 1 and true");

    # Int true
    $myobject->ScalarBoolean(dbus_boolean(1));
    is($object->get_last_message_signature, "b", "int as boolean, true");
    is($object->get_last_message_param, '1', "int as boolean, true");

    # Int false
    $myobject->ScalarBoolean(dbus_boolean(0));
    is($object->get_last_message_signature, "b", "int as boolean, false");
    is($object->get_last_message_param, '', "int as boolean, false");

    # Undefined and false
    $myobject->ScalarBoolean(dbus_boolean(undef));
    is($object->get_last_message_signature, "b", "undefined as boolean, false");
    is($object->get_last_message_param, '', "undefined as boolean, false");
    
}



TEST_INTROSPECT_TYPING: {
    my ($bus, $object, $robject, $myobject, $otherobject) = &setup;

    my $ins = Net::DBus::Binding::Introspector->new();
    $ins->add_method("ScalarString", ["string"], [], "org.example.MyObject", {}, []);
    $ins->add_method("ScalarInt16", ["int16"], [], "org.example.MyObject", {}, []);
    $ins->add_method("ScalarUInt16", ["uint16"], [], "org.example.MyObject", {}, []);
    $ins->add_method("ScalarInt32", ["int32"], [], "org.example.MyObject", {}, []);
    $ins->add_method("ScalarUInt32", ["uint32"], [], "org.example.MyObject", {}, []);
    $ins->add_method("ScalarDouble", ["double"], [], "org.example.MyObject", {}, []);
    $ins->add_method("ScalarByte", ["byte"], [], "org.example.MyObject", {}, []);
    $ins->add_method("ScalarBoolean", ["bool"], [], "org.example.MyObject", {}, []);
    $object->seed_action("org.freedesktop.DBus.Introspectable", "Introspect", 
			 reply => { return => [ $ins->format($object) ] });
    
    ##### String tests
    
    $myobject->ScalarString("Foo");
    is($object->get_last_message_signature, "s", "string as string");
    is($object->get_last_message_param, "Foo", "string as string");

    $myobject->ScalarString(2);
    is($object->get_last_message->get_signature, "s", "int as string");
    is($object->get_last_message_param, "2", "int as string");

    $myobject->ScalarString(5.234);
    is($object->get_last_message->get_signature, "s", "double as string");
    is($object->get_last_message_param, "5.234", "double as string");
    

    #### INT 16 tests

    # Positive integers
    $myobject->ScalarInt16("2");
    is($object->get_last_message_signature, "n", "string as int16");
    is($object->get_last_message_param, 2, "string as int16");

    $myobject->ScalarInt16(2);
    is($object->get_last_message_signature, "n", "int as int16");
    is($object->get_last_message_param, 2, "int as int16");

    $myobject->ScalarInt16(2.0);
    is($object->get_last_message_signature, "n", "double as int16");
    is($object->get_last_message_param, 2, "double as int16");

    # Negative integers
    $myobject->ScalarInt16("-2");
    is($object->get_last_message_signature, "n", "-ve string as int16");
  SKIP: {
      skip "sign truncation not checked", 1;
      is($object->get_last_message_param, "-2", "-ve string as int16");
  }

    $myobject->ScalarInt16(-2);
    is($object->get_last_message_signature, "n", "-ve int as int16");
  SKIP: {
      skip "sign truncation not checked", 1;
      is($object->get_last_message_param, "-2", "-ve int as int16");
  }

    $myobject->ScalarInt16(-2.0);
    is($object->get_last_message_signature, "n",  "-ve double as int16");
  SKIP: {
      skip "sign truncation not checked", 1;
      is($object->get_last_message_param, "-2.0", "-ve double as int16");
  }

    # Rounding of doubles
    $myobject->ScalarInt16(2.1);
    is($object->get_last_message_signature, "n",  "round down double as int16");
    is($object->get_last_message_param, 2, "round down double as int16");

    $myobject->ScalarInt16(2.9);
    is($object->get_last_message_signature, "n",  "round up double as int16");
  SKIP: {
      skip "double -> int rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double as int16");
  }

    $myobject->ScalarInt16(2.5);
    is($object->get_last_message_signature, "n",  "round up double threshold as int16");
  SKIP: {
      skip "double -> int rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double threshold as int16");
  }

    $myobject->ScalarInt16(-2.1);
    is($object->get_last_message_signature, "n",  "-ve round up double as int16");
    is($object->get_last_message_param, -2, "-ve round up double as int16");
        
    $myobject->ScalarInt16(-2.9);
    is($object->get_last_message_signature, "n",  "-ve round down double as int16");
  SKIP: {
      skip "double -> int rounding actually truncates", 1;
      is($object->get_last_message_param, -3, "-ve round down double as int16");
  }

    $myobject->ScalarInt16(-2.5);
    is($object->get_last_message_signature, "n",  "-ve round down double threshold as int16");
    is($object->get_last_message_param, -2, "-ve round down double threshold as int16");
    

    #### UINT 16 tests

    # Positive integers
    $myobject->ScalarUInt16("2");
    is($object->get_last_message_signature, "q", "string as uint16");
    is($object->get_last_message_param, 2, "string as uint16");

    $myobject->ScalarUInt16(2);
    is($object->get_last_message_signature, "q", "int as uint16");
    is($object->get_last_message_param, 2, "int as uint16");

    $myobject->ScalarUInt16(2.0);
    is($object->get_last_message_signature, "q", "double as uint16");
    is($object->get_last_message_param, 2, "double as uint16");

    # Negative integers
    $myobject->ScalarUInt16("-2");
    is($object->get_last_message_signature, "q", "-ve string as uint16");
  SKIP: {
      skip "sign truncation not checked", 1;
      is($object->get_last_message_param, -2, "-ve string as uint16");
  }

    $myobject->ScalarUInt16(-2);
    is($object->get_last_message_signature, "q", "-ve int as uint16");
  SKIP: {
      skip "sign truncation not checked", 1;
      is($object->get_last_message_param, -2, "-ve int as uint16");
  }

    $myobject->ScalarUInt16(-2.0);
    is($object->get_last_message_signature, "q", "-ve double as uint16");
  SKIP: {
      skip "sign truncation not checked", 1;
      is($object->get_last_message_param, -2, "-ve double as uint16");
  }


    # Rounding of doubles
    $myobject->ScalarUInt16(2.1);
    is($object->get_last_message_signature, "q", "round down double as uint16");
    is($object->get_last_message_param, 2, "round down double as uint16");

    $myobject->ScalarUInt16(2.9);
    is($object->get_last_message_signature, "q", "round up double as uint16");
  SKIP: {
      skip "double -> int rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double as uint16");
  }

    $myobject->ScalarUInt16(2.5);
    is($object->get_last_message_signature, "q", "round up double threshold as uint16");
  SKIP: {
      skip "double -> int rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double threshold as uint16");
  }
    
    #### INT 32 tests

    # Positive integers
    $myobject->ScalarInt32("2");
    is($object->get_last_message_signature, "i", "string as int32");
    is($object->get_last_message_param, 2, "string as int32");

    $myobject->ScalarInt32(2);
    is($object->get_last_message_signature, "i", "int as int32");
    is($object->get_last_message_param, 2, "int as int32");

    $myobject->ScalarInt32(2.0);
    is($object->get_last_message_signature, "i", "double as int32");
    is($object->get_last_message_param, 2, "double as int32");

    # Negative integers
    $myobject->ScalarInt32("-2");
    is($object->get_last_message_signature, "i", "-ve string as int32");
  SKIP: {
      skip "sign truncation not checked", 1;
      is($object->get_last_message_param, "-2", "-ve string as int32");
  }

    $myobject->ScalarInt32(-2);
    is($object->get_last_message_signature, "i", "-ve int as int32");
  SKIP: {
      skip "sign truncation not checked", 1;
      is($object->get_last_message_param, "-2", "-ve int as int32");
  }

    $myobject->ScalarInt32(-2.0);
    is($object->get_last_message_signature, "i",  "-ve double as int32");
  SKIP: {
      skip "sign truncation not checked", 1;
      is($object->get_last_message_param, "-2.0", "-ve double as int32");
  }

    # Rounding of doubles
    $myobject->ScalarInt32(2.1);
    is($object->get_last_message_signature, "i",  "round down double as int32");
    is($object->get_last_message_param, 2, "round down double as int32");

    $myobject->ScalarInt32(2.9);
    is($object->get_last_message_signature, "i",  "round up double as int32");
  SKIP: {
      skip "double -> int rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double as int32");
  }

    $myobject->ScalarInt32(2.5);
    is($object->get_last_message_signature, "i",  "round up double threshold as int32");
  SKIP: {
      skip "double -> int rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double threshold as int32");
  }

    $myobject->ScalarInt32(-2.1);
    is($object->get_last_message_signature, "i",  "-ve round up double as int32");
    is($object->get_last_message_param, -2, "-ve round up double as int32");
        
    $myobject->ScalarInt32(-2.9);
    is($object->get_last_message_signature, "i",  "-ve round down double as int32");
  SKIP: {
      skip "double -> int rounding actually truncates", 1;
      is($object->get_last_message_param, -3, "-ve round down double as int32");
  }

    $myobject->ScalarInt32(-2.5);
    is($object->get_last_message_signature, "i",  "-ve round down double threshold as int32");
    is($object->get_last_message_param, -2, "-ve round down double threshold as int32");
    

    #### UINT 32 tests

    # Positive integers
    $myobject->ScalarUInt32("2");
    is($object->get_last_message_signature, "u", "string as uint32");
    is($object->get_last_message_param, 2, "string as uint32");

    $myobject->ScalarUInt32(2);
    is($object->get_last_message_signature, "u", "int as uint32");
    is($object->get_last_message_param, 2, "int as uint32");

    $myobject->ScalarUInt32(2.0);
    is($object->get_last_message_signature, "u", "double as uint32");
    is($object->get_last_message_param, 2, "double as uint32");

    # Negative integers
    $myobject->ScalarUInt32("-2");
    is($object->get_last_message_signature, "u", "-ve string as uint32");
  SKIP: {
      skip "sign truncation not checked", 1;
      is($object->get_last_message_param, -2, "-ve string as uint32");
  }

    $myobject->ScalarUInt32(-2);
    is($object->get_last_message_signature, "u", "-ve int as uint32");
  SKIP: {
      skip "sign truncation not checked", 1;
      is($object->get_last_message_param, -2, "-ve int as uint32");
  }

    $myobject->ScalarUInt32(-2.0);
    is($object->get_last_message_signature, "u", "-ve double as uint32");
  SKIP: {
      skip "sign truncation not checked", 1;
      is($object->get_last_message_param, -2, "-ve double as uint32");
  }


    # Rounding of doubles
    $myobject->ScalarUInt32(2.1);
    is($object->get_last_message_signature, "u", "round down double as uint32");
    is($object->get_last_message_param, 2, "round down double as uint32");

    $myobject->ScalarUInt32(2.9);
    is($object->get_last_message_signature, "u", "round up double as uint32");
  SKIP: {
      skip "double -> int rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double as uint32");
  }

    $myobject->ScalarUInt32(2.5);
    is($object->get_last_message_signature, "u", "round up double threshold as uint32");
  SKIP: {
      skip "double -> int rounding actually truncates", 1;
      is($object->get_last_message_param, 3, "round up double threshold as uint32");
  }
    
    #### Double tests
    
    # Double
    $myobject->ScalarDouble(5.234);
    is($object->get_last_message_signature, "d", "double as double");
    is($object->get_last_message_param, 5.234, "double as double");

    # Stringized Double
    $myobject->ScalarDouble("2.1");
    is($object->get_last_message_signature, "d", "string as double");
    is($object->get_last_message_param, 2.1, "string as double");

    # Integer -> double conversion
    $myobject->ScalarDouble(2);
    is($object->get_last_message_signature, "d", "int as double");
    is($object->get_last_message_param, 2.0, "int as double");

    
    # -ve Double
    $myobject->ScalarDouble(-5.234);    
    is($object->get_last_message_signature, "d", "-ve double as double");
    is($object->get_last_message_param, -5.234, "-ve double as double");

    # -ve Stringized Double
    $myobject->ScalarDouble("-2.1");
    is($object->get_last_message_signature, "d", "-ve string as double");
    is($object->get_last_message_param, -2.1, "-ve string as double");

    # -ve Integer -> double conversion
    $myobject->ScalarDouble(-2);
    is($object->get_last_message_signature, "d", "-ve int as double");
    is($object->get_last_message_param, -2.0, "-ve int as double");


    #### Byte tests
    
    # Int
    $myobject->ScalarByte(7);
    is($object->get_last_message_signature, "y", "int as byte");
    is($object->get_last_message_param, 7, "int as byte");

    # Double roudning
    $myobject->ScalarByte(2.6);
    is($object->get_last_message_signature, "y", "double as byte");
  SKIP: {
      skip "double rounding not sorted", 1;
      is($object->get_last_message_param, 3, "double as byte");
  }

    # Range overflow
    $myobject->ScalarByte(10000);
    is($object->get_last_message_signature, "y", "int as byte overflow");
  SKIP: {
      skip "byte overflow not checked", 1;
      is($object->get_last_message_param, 2, "int as byte overflow");
  }

    
    # -ve Int
    $myobject->ScalarByte(-7);
    is($object->get_last_message_signature, "y", "-ve int as byte");
  SKIP: {
      skip "byte sign truncation not double checked", 1;
      is($object->get_last_message_param, 2, "-ve int as byte");
  }

    # -ve Double roudning
    $myobject->ScalarByte(-2.6);
    is($object->get_last_message_signature, "y", "double as byte");
  SKIP: {
      skip "byte sign truncation not double checked", 1;
      is($object->get_last_message_param, 2, "-ve double as byte");
  }

    # -ve Range overflow
    $myobject->ScalarByte(-10000);
    is($object->get_last_message_signature, "y", "-ve int as byte overflow");
  SKIP: {
      skip "byte sign truncation not double checked", 1;
      is($object->get_last_message_param, 2, "-ve int as byte overflow");
  }
    
    ##### Boolean 
    
    # String, O and false
    $myobject->ScalarBoolean("0");
    is($object->get_last_message_signature, "b", "string as boolean, 0 and false");
    is($object->get_last_message_param, '', "string as boolean, 0 and false");

    # String, O but true
    $myobject->ScalarBoolean("0true");
    is($object->get_last_message_signature, "b", "string as boolean, 0 but true");
    is($object->get_last_message_param, 1, "string as boolean, 0 but true");

    # String, 1 and true
    $myobject->ScalarBoolean("1true");
    is($object->get_last_message_signature, "b", "string as boolean, 1 and true");
    is($object->get_last_message_param, 1, "string as boolean, 1 and true");

    # Int true
    $myobject->ScalarBoolean(1);
    is($object->get_last_message_signature, "b", "int as boolean, true");
    is($object->get_last_message_param, 1, "int as boolean, true");

    # Int false
    $myobject->ScalarBoolean(0);
    is($object->get_last_message_signature, "b", "int as boolean, false");
    is($object->get_last_message_param, '', "int as boolean, false");

    # Undefined and false
    $myobject->ScalarBoolean(undef);
    is($object->get_last_message_signature, "b", "undefined as boolean, false");
    is($object->get_last_message_param, '', "undefined as boolean, false");
    
}

exit 0;

sub setup {
    my $bus = Net::DBus->test;
    my $service = $bus->export_service("org.cpan.Net.Bus.test");
    
    my $object = Net::DBus::Test::MockObject->new($service, "/org/example/MyObject");
    
    my $rservice = $bus->get_service("org.cpan.Net.Bus.test");
    my $robject = $rservice->get_object("/org/example/MyObject");
    my $myobject = $robject->as_interface("org.example.MyObject");
    my $otherobject = $robject->as_interface("org.example.OtherObject");

    $object->seed_action("org.example.MyObject", "ScalarString", reply => { return => [] });
    $object->seed_action("org.example.MyObject", "ScalarInt16", reply => { return => [] });
    $object->seed_action("org.example.MyObject", "ScalarUInt16", reply => { return => [] });
    $object->seed_action("org.example.MyObject", "ScalarInt32", reply => { return => [] });
    $object->seed_action("org.example.MyObject", "ScalarUInt32", reply => { return => [] });
    $object->seed_action("org.example.MyObject", "ScalarDouble", reply => { return => [] });
    $object->seed_action("org.example.MyObject", "ScalarByte", reply => { return => [] });
    $object->seed_action("org.example.MyObject", "ScalarBoolean", reply => { return => [] });

    
    return ($bus, $object, $robject, $myobject, $otherobject);
}

