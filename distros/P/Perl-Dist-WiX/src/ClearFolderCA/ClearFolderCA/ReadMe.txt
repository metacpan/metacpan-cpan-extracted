This is a Visual Studio 2005 solution for the ClearFolder Custom Action 
required for installations of perl.

(unfortunately, the version of MingW that Strawberry Perl uses does not have the 
libraries required to compile a custom action. So Visual Studio it is.)

The compiled version will be in Perl-Dist-WiX-x.xxx.tar.gz/share/ClearFolderCA.dll.

[Note for csjewell@cpan.org: Reapply r7563 on ClearFolderCA.cpp once we make our own dialog for uninstall progress.]