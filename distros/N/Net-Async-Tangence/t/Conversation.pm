package t::Conversation;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(
   %S2C
   %C2S

   $MSG_OK
);

our %S2C;
our %C2S;

our $MSG_OK = "\x80" . "\0\0\0\0";

# This module contains the string values used in various testing scripts that
# act as an example conversation between server and client. The strings are
# kept here in order to avoid mass duplication between the other testing
# modules, and to try to shield unwary visitors from the mass horror that is
# the following collection of large hex-encoded strings.

# If you are sitting comfortably, our story begings with the client...

# MSG_INIT
$C2S{INIT} =
   "\x7f" . "\0\0\0\6" .
   "\x02" . "\0" .
   "\x02" . "\4" .
   "\x02" . "\3";

# MSG_INITED
$S2C{INITED} =
   "\xff" . "\0\0\0\4" .
   "\x02" . "\0" .
   "\x02" . "\4";

# MSG_GETROOT
$C2S{GETROOT} = 
   "\x40" . "\0\0\0\x0b" .
   "\x2a" . "testscript";
$S2C{GETROOT} =
   "\x82" . "\0\0\0\xf8" .
   "\xe2" . "\x29t.TestObj" .
            "\x02\1" .
            "\xa4" . "\x02\1" .
                     "\x62" . "\x26method"  . "\xa2" . "\x02\2" .
                                                       "\x42" . "\x23int" .
                                                                "\x23str" .
                                                       "\x23str" .
                              "\x28noreturn" . "\xa2" . "\x02\2" .
                                                        "\x40" .
                                                        "\x20" .
                     "\x61" . "\x25event" . "\xa1" . "\x02\3" .
                                                     "\x42" . "\x23int" .
                                                              "\x23str" .
                     "\x68" . "\x25array" . "\xa3" . "\x02\4" .
                                                     "\x02\4" .
                                                     "\x23int" .
                                                     "\x00" .
                              "\x24hash" . "\xa3" . "\x02\4" .
                                                    "\x02\2" .
                                                    "\x23int" .
                                                    "\x00" .
                              "\x25items" . "\xa3" . "\x02\4" .
                                                     "\x02\1" .
                                                     "\x29list(obj)" .
                                                     "\x00" .
                              "\x26objset" . "\xa3" . "\x02\4" .
                                                      "\x02\5" .
                                                      "\x23obj" .
                                                      "\x00" .
                              "\x25queue" . "\xa3" . "\x02\4" .
                                                     "\x02\3" .
                                                     "\x23int" .
                                                     "\x00" .
                              "\x27s_array" . "\xa3" . "\x02\4" .
                                                       "\x02\4" .
                                                       "\x23int" .
                                                       "\x01" .
                              "\x28s_scalar" . "\xa3" . "\x02\4" .
                                                        "\x02\1" .
                                                        "\x23int" .
                                                        "\x01" .
                              "\x26scalar" . "\xa3" . "\x02\4" .
                                                      "\x02\1" .
                                                      "\x23int" .
                                                      "\x00" .
                     "\x40" .
            "\x42" . "\x27s_array" .
                     "\x28s_scalar" .
   "\xe1" . "\x02\1" .
            "\x02\1" .
            "\x42" . "\x40" .
                     "\x04\x01\xc8" .
   "\x84" . "\0\0\0\1";

# MSG_GETREGISTRY
$C2S{GETREGISTRY} =
   "\x41" . "\0\0\0\0";
$S2C{GETREGISTRY} =
   "\x82" . "\0\0\0\x84" .
   "\xe2" . "\x31Tangence.Registry" .
            "\x02\2" .
            "\xa4" . "\x02\1" .
                     "\x61" . "\x29get_by_id" . "\xa2" . "\x02\2" . 
                                                         "\x41" . "\x23" . "int" .
                                                         "\x23" . "obj" .
                     "\x62" . "\x32object_constructed" . "\xa1" . "\x02\3" .
                                                         "\x41" . "\x23" . "int" .
                              "\x30object_destroyed"   . "\xa1" . "\x02\3" .
                                                         "\x41" . "\x23" . "int" .
                     "\x61" . "\x27objects" . "\xa3" . "\x02\4" .
                                                       "\x02\2" .
                                                       "\x23" . "str" .
                                                       "\x00" .
                     "\x40" .
            "\x40" .
   "\xe1" . "\x02\0" .
            "\x02\2" .
            "\x40" .
   "\x84" . "\0\0\0\0";

# MSG_CALL
$C2S{CALL} =
   "\1" . "\0\0\0\x11" .
   "\x02\x01" .
   "\x26method" .
   "\x02\x0a" .
   "\x25hello";
# MSG_RESULT
$S2C{CALL} =
   "\x82" . "\0\0\0\x09" .
   "\x2810/hello";
$C2S{CALL_NORETURN} =
   "\1" . "\0\0\0\x0b" .
   "\x02\x01" .
   "\x28noreturn";
$S2C{CALL_NORETURN} =
   "\x82" . "\0\0\0\0";

# MSG_SUBSCRIBE
$C2S{SUBSCRIBE} =
   "\2" . "\0\0\0\x08" .
   "\x02\1" .
   "\x25event";
$S2C{SUBSCRIBED} =
   "\x83" . "\0\0\0\0";
$C2S{UNSUBSCRIBE} =
   "\3" . "\0\0\0\x08" .
   "\x02\1" .
   "\x25event";

# MSG_EVENT
$S2C{EVENT} =
   "\4" . "\0\0\0\x0e" .
   "\x02\1" .
   "\x25event" .
   "\x02\x14" .
   "\x23bye";

# MSG_GETPROP
$C2S{GETPROP} =
   "\5" . "\0\0\0\x09" .
   "\x02\1" .
   "\x26scalar";
$S2C{GETPROP_123} =
   "\x82" . "\0\0\0\2" .
   "\x02\x7b";
$S2C{GETPROP_147} =
   "\x82" . "\0\0\0\2" .
   "\x02\x93";

# MSG_GETPROPELEM
$C2S{GETPROPELEM_HASH} =
   "\x0b" . "\0\0\0\x0b" .
   "\x02\1" .
   "\x24hash" .
   "\x23two";
$S2C{GETPROPELEM_HASH} =
   "\x82" . "\0\0\0\2" .
   "\x02\2";
$C2S{GETPROPELEM_ARRAY} =
   "\x0b" . "\0\0\0\x0a" .
   "\x02\1" .
   "\x25array" .
   "\x02\1";
$S2C{GETPROPELEM_ARRAY} =
   "\x82" . "\0\0\0\2" .
   "\x02\2";

# MSG_SETPROP
$C2S{SETPROP} =
   "\6" . "\0\0\0\x0b" .
   "\x02\1" .
   "\x26scalar" .
   "\x02\x87";

# MSG_GETPROPELEM
$C2S{GETPROPELEM_BLUE} =
   "\x0b" . "\0\0\0\x0f" .
   "\x02" . "\x01" .
   "\x27" . "colours" .
   "\x24" . "blue";
$S2C{GETPROPELEM_BLUE} =
   "\x82" . "\0\0\0\2" .
   "\x02" . "\x01";

# MSG_WATCH
$C2S{WATCH} =
   "\7" . "\0\0\0\x0a" .
   "\x02\1" .
   "\x26scalar" .
   "\x00";
$S2C{WATCHING} =
   "\x84" . "\0\0\0\0";
$C2S{UNWATCH} =
   "\x08" . "\0\0\0\x09" .
   "\x02\1" .
   "\x26scalar";

# MSG_WATCH_ITER
$C2S{WATCH_ITER} =
   "\x0c" . "\0\0\0\x0a" .
   "\x02\1" .
   "\x25queue" .
   "\x02\1";
$S2C{WATCHING_ITER} =
   "\x85" . "\0\0\0\6" .
   "\x02\1" .
   "\x02\0" .
   "\x02\2";
$C2S{ITER_NEXT_1} =
   "\x0d" . "\0\0\0\6" .
   "\x02\1" .
   "\x02\1" .
   "\x02\1";
$S2C{ITER_NEXT_1} =
   "\x86" . "\0\0\0\4" .
   "\x02\0" .
   "\x02\1";
$C2S{ITER_NEXT_5} =
   "\x0d" . "\0\0\0\6" .
   "\x02\1" .
   "\x02\1" .
   "\x02\5";
$S2C{ITER_NEXT_5} =
   "\x86" . "\0\0\0\6" .
   "\x02\1" .
   "\x02\2" .
   "\x02\3";
$C2S{ITER_NEXT_BACK} =
   "\x0d" . "\0\0\0\6" .
   "\x02\1" .
   "\x02\2" .
   "\x02\1";
$S2C{ITER_NEXT_BACK} =
   "\x86" . "\0\0\0\4" .
   "\x02\2" .
   "\x02\3";
$C2S{ITER_DESTROY} =
   "\x0e" . "\0\0\0\2" .
   "\x02\1";

# MSG_UPDATE
$S2C{UPDATE_SCALAR_147} =
   "\x09" . "\0\0\0\x0d" .
   "\x02\1" .
   "\x26scalar" .
   "\x02\1" .
   "\x02\x93";
$S2C{UPDATE_SCALAR_159} =
   "\x09" . "\0\0\0\x0d" .
   "\x02\1" .
   "\x26scalar" .
   "\x02\1" .
   "\x02\x9f";
$S2C{UPDATE_S_SCALAR_468} =
   "\x09" . "\0\0\0\x10" .
   "\x02\1" .
   "\x28s_scalar" .
   "\x02\1" .
   "\x04\x01\xd4";

# MSG_DESTROY
$S2C{DESTROY} = 
   "\x0a" . "\0\0\0\2" .
   "\x02\1";
