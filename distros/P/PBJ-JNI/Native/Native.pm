# Copyright (c) 2001 Ping Liang
# All rights reserved.
#
# This program is free software; you can use, redistribute and/or
# modify it under the same terms as Perl itself.
#
# $Id: Native.pm,v 1.4 2002/01/01 20:49:54 liang Exp $

package PBJ::JNI::Native;

our $VERSION = '0.1';

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

bootstrap PBJ::JNI::Native $VERSION;

sub DESTROY() {
  #die "JNI::Native object destroyed.\n";
}

1;
__END__

=head1 NAME

PBJ::JNI::Native - Perl interface to Java JNI

=head1 SYNOPSIS

    # use through the PBJ::JNI::JavaVM module, not directly.
    use PBJ::JNI::JavaVM;

    my ($env, $jvm, @vm_opts);
    my ($cls, $fid, $mid, $out);

    # Create the Java VM
    @vm_opts = ("-Xrs", "-Xcheck:jni");
    $jvm = new PBJ::JNI::JavaVM();
    $env = $jvm->get_env(@vm_opts);

    $env->PushLocalFrame(16) == 0 or die;
    $cls = $env->FindClass("java/lang/System") or die;
    $fid = $env->GetStaticFieldID($cls, "out", "Ljava/io/PrintStream;") or die;
    $out = $env->GetStaticObjectField($cls, $fid) or die;
    $cls = $env->GetObjectClass($out) or die;
    $mid = $env->GetMethodID($cls, "println", "(I)V") or die;
    $env->CallVoidMethod($out, $mid, $env->cast("I", 12345));
    $env->PopLocalFrame(0);


=head1 DESCRIPTION

This is the native interface to JNI library.  All function names are
closely resembling the ones in the Java JNI library, with some
necessary exceptions.  This module should not be used directly.  All
subroutines are called via the PBJ::JNI::JNIEnv module.


=head2 EXPORT

None.


=head1 AUTHOR

Ping Liang, E<lt>ping@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>.

=head1 COPYRIGHT and LICENSE

Copyright (c) 2001 Ping Liang
All rights reserved.

THIS PROGRAM IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

This program is licensed under the same terms as Perl itself. For more
information see the README or Artistic files provided with the Perl
distribution.

=cut
