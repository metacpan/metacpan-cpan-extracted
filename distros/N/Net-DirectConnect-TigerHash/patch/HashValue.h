--- ./eiskaltdcpp/dcpp/HashValue.h	2016-09-05 11:46:07.152281387 +0300
+++ dcpp/HashValue.h	2016-09-05 11:50:32.714634679 +0300
@@ -18,13 +18,15 @@
 
 #pragma once
 
+/*
 #include "FastAlloc.h"
+*/
 #include "Encoder.h"
 
 namespace dcpp {
 
 template<class Hasher>
-struct HashValue : FastAlloc<HashValue<Hasher> >{
+struct HashValue /* : FastAlloc<HashValue<Hasher> > */ {
     static const size_t BITS = Hasher::BITS;
     static const size_t BYTES = Hasher::BYTES;
 
