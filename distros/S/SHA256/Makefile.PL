use ExtUtils::MakeMaker;
use Config;

WriteMakefile(
    'NAME' => "Digest::SHA256",
    'OBJECT' => q[sha256$(OBJ_EXT) _sha256$(OBJ_EXT) sha384_512$(OBJ_EXT)],
    VERSION_FROM => "SHA256.pm",
    'realclean'  => {'FILES' => 'endian.h'}
);

if (exists($Config{'byteorder'}) and defined($Config{'byteorder'})) {
  if (-e 'endian.h') {
    warn "Warning: overwriting endian.h\n";
  } else {
    print "Writing endian.h for SHA256\n";
  }
  open(EOUT, '>endian.h')
    or die "error: unable to open 'endian.h' for writing\n";
  print EOUT <<"END_OF_STRING";


#ifndef ENDIAN_H
#define ENDIAN_H

/* Warning! this file is automatically generated; changes WILL disappear */

#define BYTEORDER $Config{'byteorder'}

#endif /* ENDIAN_H */
END_OF_STRING
  close EOUT
    or die "error: unable to properly close 'endian.h'\n";
} else {
  die "error: the parameter 'byteorder' is not defined in Config.\n";
}
