#!/usr/bin/perl

use strict;

use OOP;

 my $myProto = {
            one => 1,
            two => 2,
            three => {
                      hi => {
                             dataType => 'hash',
                             allowEmpty => 1,
                             locked => 1,
                             maxLength => 3,
                             minLength => 1,
                             readAccess => 1,
                             required => 1,
                             value => {
                                       bye => '',
                                       ebye => {
                                                 dataType => 'scalar',
                                                 allowEmpty => 1,
                                                 locked => 0,
                                         	 maxLength => 3,
                                                 minLength => 0,
                                         	 readAccess => 0,     
                                                 required => 0,
                                         	 value => '',
                                         	 writeAccess => 0
                                         	}
                                         
                                         	
                                      },
                             writeAccess => 1                                      
                            }
                     }
            };

 my $myHash = {
           one => 1,
           two => 2,
           three => {
                     hi => {
                            bye => '12345678'
                           }
                    }
           };      
           
my $obj = OOP->new({
                    ARGS=> $myHash,
                    PROTOTYPE => $myProto
                   });

       
print "\nWelcome to the OOP test script!\n\n";                   

print "Step 1. Checks proper prototype adherance.\n";


print "Testing read access to public property....... ";
eval { $obj->{PROPERTIES}->{three}{hi}{bye} };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "Testing write access to public property...... ";
eval { $obj->{PROPERTIES}->{three}{hi}{bye} = '123' };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "Testing dynamic element creation............. ";
eval { $obj->{PROPERTIES}->{three}{hi}{xbye} = '123' };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "Testing dynamically created element removal.. ";
eval { delete $obj->{PROPERTIES}->{three}{hi}{xbye}; };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "Testing looping through elements via each().. ";
eval { my %hash = %{$obj->{PROPERTIES}->{three}{hi}}; my $c = 0 ; while (my($x, $y) = each(%hash)) { die 'Caught infinite loop' if $c >= 10; $c++ } };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "Testing looping through elements via keys().. ";
eval { my %hash = %{$obj->{PROPERTIES}->{three}{hi}}; my $c = 0 ; for (keys(%hash)) { die 'Caught infinite loop' if $c >= 10; $c++ } };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "\nStep 2. Checks prototype violation handling.\n";

print "Testing read access to private property...... ";
eval { $obj->{PROPERTIES}->{three}{hi}{ebye} };
print $@ =~ /Direct read access(.*)at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "Testing write access violation............... ";
eval { $obj->{PROPERTIES}->{three}{hi}{ebye} = '123' };
print $@ =~ /read-only(.*)at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "Testing dynamic element creation violation... ";
eval { $obj->{PROPERTIES}->{three}->{hi}->{xbye} = '123'; $obj->{PROPERTIES}->{three}->{hi}->{zbye} = '123'; $obj->{PROPERTIES}->{three}->{hi}->{mbye} = '123'; };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "Testing restricted element removal........... ";
eval { delete $obj->{PROPERTIES}->{three}{hi} };
print $@ =~ /may not be removed(.*)at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "Testing data type incompatibility overwrite.. ";
eval { $obj->{PROPERTIES}->{three}{hi} = 'foobar' };
print $@ =~ /Attempt to(.*)at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "Testing dynamic element overwrite............ ";
eval { $obj->{PROPERTIES}->{three}{hi} = 'hello' };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "Testing public property data type mismatch... ";
eval { $obj->{PROPERTIES}->{three}{hi}{bye} = [333] };
print $@ =~ /Attempt to pass improper(.*)at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "\nStep 3. Checks various data structure tasks.\n";

print "Testing clearing of properties............... ";
eval { %{$obj->{PROPERTIES}} = () };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "Testing clearing of parameters............... ";
eval { %{$myHash} = () };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "\nStep 4. Checks alternate prototype scenarios.\n";


$myProto = {
            one => 1,
            two => 2,
            three => {
                      hi => {
                             dataType => 'hash',
                             allowEmpty => 1,
                             locked => 1,
                             maxLength => 6,
                             minLength => 1,
                             readAccess => 1,
                             required => 0,
                             value => {
                                       bye => '',
                                       ebye => {
                                                 dataType => 'scalar',
                                                 allowEmpty => 1,
                                                 locked => 1,
                                         	 maxLength => 5,
                                                 minLength => 1,
                                         	 readAccess => 1,     
                                                 required => 1,
                                         	 value => '',
                                         	 writeAccess => 1
                                         	}
                                         	
                                      },
                             writeAccess => 1                                      
                            }
                     }
            };

 my $myHash = {
           one => 1,
           two => 2,
           three => {
                     hi => {
                           }
                    }
           };      

#print "BYE: " . $myHash->{three}{hi}{bye};

my $obj = OOP->new({
                    ARGS=> $myHash,
                    PROTOTYPE => $myProto
                   });

print "Testing for missing required element......... ";
eval { $obj->{PROPERTIES}->{three}{hi}{ebye} = '1234' };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

%{$myHash} = ();

$myProto = {
            one => 1,
            two => 2,
            three => {
                      hi => {
                             dataType => 'hash',
                             allowEmpty => 1,
                             locked => 1,
                             maxLength => 6,
                             minLength => 1,
                             readAccess => 1,
                             required => 0,
                             value => {
                                       bye => {},
                                       ebye => {
                                                dataType => 'scalar',
                                                allowEmpty => 1,
                                                locked => 1,
                                         	maxLength => 5,
                                                minLength => 2,
                                         	readAccess => 1,     
                                                required => 1,
                                         	value => '',
                                         	writeAccess => 1
                                               }
                                         	
                                      },
                             writeAccess => 1                                      
                            }
                     }
            };

 my $myHash = {
           one => 1,
           two => 2,
           three => {
                     hi => {
                            ebye => 'hello'
                           }
                    }
           };      

#print "BYE: " . $myHash->{three}{hi}{bye};

my $obj = OOP->new({
                    ARGS=> $myHash,
                    PROTOTYPE => $myProto
                   });

print "Testing for oversized scalar value........... ";
eval { $obj->{PROPERTIES}->{three}{hi}{ebye} = '123456' };
print $@ =~ /would be too long(.*)at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "Testing for undersized scalar value.......... ";
eval { $obj->{PROPERTIES}->{three}{hi}{ebye} = '1' };
print $@ =~ /would be shorter(.*)at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";


print "Testing for undersized empty scalar value.... ";
eval { $obj->{PROPERTIES}->{three}{hi}{ebye} = '' };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "Testing for locked element removal again..... ";
eval { delete $obj->{PROPERTIES}->{three}{hi}{ebye}; };
print $@ =~ /may not be removed(.*)at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "Testing unlocked element removal............. ";
eval { delete $obj->{PROPERTIES}->{three}{hi}{bye} };
print $@;
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "Testing dynamic element recreation........... ";
eval { $obj->{PROPERTIES}->{three}{hi}{bye} = {'foo' => 'bar'} };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "Testing dynamically recreated element read... ";
eval { $obj->{PROPERTIES}->{three}{hi}{bye} };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "Testing constant value overwrite............. ";
eval { $obj->{PROPERTIES}->{one} = 2 };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "Testing scalar element array mismatch........ ";
eval { $obj->{PROPERTIES}->{three}{hi}{ebye} = [2] };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "Testing scalar element hash mismatch......... ";
eval { $obj->{PROPERTIES}->{three}{hi}{ebye} = {'foo' => 'bar'} };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "Testing hash element array mismatch.......... ";
eval { $obj->{PROPERTIES}->{three}{hi}{bye} = [2] };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "Testing hash element scalar mismatch......... ";
eval { $obj->{PROPERTIES}->{three}{hi}{bye} = 1 };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "Testing dynamic array element creation....... ";
eval { $obj->{PROPERTIES}->{three}{hi}{joe} = ['shmo'] };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "Testing created element data mismatch........ ";
eval { $obj->{PROPERTIES}->{three}{hi}{joe} = 'hello' };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

print "Testing overwritten element read............. ";
eval { $obj->{PROPERTIES}->{three}{hi}{joe} };
print $@ =~ /at (.\/)?test.pl line \d+/ ? 'Error' : 'Ok';
print "\n";

%{$myHash} = ();

$myProto = {
            one => 1,
            two => 2,
            three => {
                      hi => {
                             dataType => 'hash',
                             allowEmpty => 1,
                             locked => 1,
                             maxLength => 3,
                             minLength => 1,
                             readAccess => 1,
                             required => 0,
                             value => {
                                       bye => {},
                                       ebye => {
                                                dataType => 'scalar',
                                                allowEmpty => 1,
                                                locked => 1,
                                         	maxLength => 5,
                                                minLength => 2,
                                         	readAccess => 1,     
                                                required => 1,
                                         	value => '',
                                         	writeAccess => 1
                                               }
                                         	
                                      },
                             writeAccess => 0                                      
                            }
                     }
            };

 my $myHash = {
           one => 1,
           two => 2,
           three => {
                     hi => {
                            ebye => 'hello'
                           }
                    }
           };      

#print "BYE: " . $myHash->{three}{hi}{bye};

my $obj = OOP->new({
                    ARGS=> $myHash,
                    PROTOTYPE => $myProto
                   });


print "Testing dynamic element creation violation... ";
eval { $obj->{PROPERTIES}->{three}{hi}{joe} = ['shmo'] };
print $@ =~ /is write protected(.*)at (.\/)?test.pl line \d+/ ? 'Ok' : 'Error';
print "\n";

print "\n";

print "Test complete.\n";
