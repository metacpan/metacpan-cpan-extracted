--- ./eiskaltdcpp/dcpp/Encoder.cpp	2016-09-05 11:46:07.148281291 +0300
+++ dcpp/Encoder.cpp	2016-09-05 11:50:47.182980819 +0300
@@ -19,7 +19,9 @@
 #include "stdinc.h"
 #include "Encoder.h"
 
+/*
 #include "Exception.h"
+*/
 
 #include <cstring>
 
@@ -116,7 +118,7 @@
         return c - 'A';
     if (c >= 'a' && c <= 'f')
         return c - 'a';
-    throw Exception("can't decode");
+    //throw Exception("can't decode");
 }
 
 void Encoder::fromBase16(const char* src, uint8_t* dst, size_t len) {
