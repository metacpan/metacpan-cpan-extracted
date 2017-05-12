package PBJ::JNI;

our $VERSION = '0.1';

=head1 NAME

PBJ::JNI - Full access to and from Java virtual machine from Perl.


=head1 SYNOPSIS

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


=head1 WARNING 

This software is still in alpha stage.  It may not be reliable and its
features and APIs may change in the future releases.

=head1 DESCRIPTION

The C<PBJ::JNI> package allows you to link with your Java virtual
machine and directly access Java classes from Perl.  It also allows a
mechanism to create callbacks from Java program to Perl subroutines.

The package focuses on providing a set of APIs that closely resemble
the native JNI interface. This basically means that you can write an
ordinary JNI program in Perl instead of in C or C++.  This provides a
quicker way to writing wrappers to invoke programs written in Java and
therefore introduce Java libraries to the Perl without the trouble of
writing low level C/C++ programs.

You will need to know how JNI works in order to use this package.
This package is by definition very primitive.  If you don't understand
thoroughly on how JNI works and try to use the feature of this package,
you can easily crash your program or create memory leaks.  So don't
do that.

It is my hope that somebody with proper skills in JNI and Perl can
write wrappers for a set of popular Java libraries, such as JDBC, XML
parser, JMS (that I am working on), and other useful Java packages so
that a Perl programmer can use them directly in a pure Perl
environment without knowing anything about JNI.

=head1 EXAMPLES

Please refer to the test programs in the "t" directory of the
distribution for some simple examples.

=head1 LIMITATIONS

Among the known limitations in this package:

=over 4

=item 1

use system malloc only

=item 2

do not work with "hotspot".

=back

=head1 MODULES

 - PBJ::JNI::JavaVM
 - PBJ::JNI::JNIEnv
 - PBJ::JNI::Util
 - PBJ::JNI::Native


=head1 AUTHOR

Ping Liang, E<lt>ping@cpan.orgE<gt>

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


