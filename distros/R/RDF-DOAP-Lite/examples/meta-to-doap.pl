#!/usr/bin/env perl

use CPAN::Meta;
use CPAN::Changes;
use RDF::DOAP::Lite;

my $doap = RDF::DOAP::Lite->new(
	meta    => get_meta(),
	changes => get_changes(),
);
$doap->doap_xml( \*STDOUT );

sub get_meta { CPAN::Meta->load_json_string(<<'END_META') } sub get_changes { CPAN::Changes->load_string(<<'END_CHANGES') }
{
   "abstract" : "Moops Object-Oriented Programming Sugar",
   "author" : [
      "Toby Inkster (TOBYINK) <tobyink@cpan.org>"
   ],
   "dynamic_config" : 1,
   "generated_by" : "Dist::Inkt::Profile::TOBYINK version 0.010, CPAN::Meta::Converter version 2.120921",
   "keywords" : [],
   "license" : [
      "perl"
   ],
   "meta-spec" : {
      "url" : "http://search.cpan.org/perldoc?CPAN::Meta::Spec",
      "version" : "2"
   },
   "name" : "Moops",
   "no_index" : {
      "directory" : [
         "eg",
         "examples",
         "inc",
         "t",
         "xt"
      ]
   },
   "optional_features" : {
      "Moo" : {
         "description" : "allow classes and roles to be built with Moo",
         "prereqs" : {
            "runtime" : {
               "suggests" : {
                  "MooX::HandlesVia" : "0"
               }
            }
         },
         "x_default" : 1
      },
      "Moose" : {
         "description" : "allow classes and roles to be built with Moose",
         "prereqs" : {
            "runtime" : {
               "recommends" : {
                  "MooseX::XSAccessor" : "0"
               },
               "requires" : {
                  "Moose" : "2.0600"
               }
            },
            "test" : {
               "suggests" : {
                  "MooseX::Types::Common::Numeric" : "0"
               }
            }
         },
         "x_default" : 0
      },
      "Mouse" : {
         "description" : "allow classes and roles to be built with Mouse",
         "prereqs" : {
            "runtime" : {
               "requires" : {
                  "Mouse" : "1.00"
               }
            }
         },
         "x_default" : 0
      },
      "Tiny" : {
         "description" : "allow classes and roles to be built with Class::Tiny/Role::Tiny",
         "prereqs" : {
            "runtime" : {
               "requires" : {
                  "Class::Tiny::Antlers" : "0",
                  "Role::Tiny" : "1.000000"
               }
            }
         },
         "x_default" : 0
      }
   },
   "prereqs" : {
      "configure" : {
         "requires" : {
            "ExtUtils::MakeMaker" : "6.17"
         }
      },
      "develop" : {
         "recommends" : {
            "Dist::Inkt" : "0"
         }
      },
      "runtime" : {
         "requires" : {
            "Devel::Pragma" : "0.54",
            "Function::Parameters" : "1.0301",
            "Import::Into" : "1.000000",
            "Keyword::Simple" : "0.01",
            "Module::Runtime" : "0.013",
            "Moo" : "1.003000",
            "MooX::late" : "0.014",
            "MooseX::MungeHas" : "0.002",
            "Scalar::Util" : "1.24",
            "Try::Tiny" : "0.12",
            "Type::Utils" : "0.024",
            "namespace::sweep" : "0.006",
            "perl" : "5.014",
            "true" : "0.18"
         }
      },
      "test" : {
         "requires" : {
            "Test::Fatal" : "0",
            "Test::More" : "0.96",
            "Test::Requires" : "0"
         },
         "suggests" : {
            "Types::XSD::Lite" : "0.003"
         }
      }
   },
   "provides" : {
      "Moops" : {
         "file" : "lib/Moops.pm",
         "version" : "0.022"
      },
      "Moops::ImportSet" : {
         "file" : "lib/Moops/ImportSet.pm",
         "version" : "0.022"
      },
      "Moops::Keyword" : {
         "file" : "lib/Moops/Keyword.pm",
         "version" : "0.022"
      },
      "Moops::Keyword::Class" : {
         "file" : "lib/Moops/Keyword/Class.pm",
         "version" : "0.022"
      },
      "Moops::Keyword::Library" : {
         "file" : "lib/Moops/Keyword/Library.pm",
         "version" : "0.022"
      },
      "Moops::Keyword::Role" : {
         "file" : "lib/Moops/Keyword/Role.pm",
         "version" : "0.022"
      },
      "Moops::MethodModifiers" : {
         "file" : "lib/Moops/MethodModifiers.pm",
         "version" : "0.022"
      },
      "Moops::Parser" : {
         "file" : "lib/Moops/Parser.pm",
         "version" : "0.022"
      },
      "Moops::TraitFor::Keyword::assertions" : {
         "file" : "lib/Moops/TraitFor/Keyword/assertions.pm",
         "version" : "0.022"
      },
      "Moops::TraitFor::Keyword::dirty" : {
         "file" : "lib/Moops/TraitFor/Keyword/dirty.pm",
         "version" : "0.022"
      },
      "Moops::TraitFor::Keyword::mutable" : {
         "file" : "lib/Moops/TraitFor/Keyword/mutable.pm",
         "version" : "0.022"
      },
      "Moops::TraitFor::Keyword::ro" : {
         "file" : "lib/Moops/TraitFor/Keyword/ro.pm",
         "version" : "0.022"
      },
      "Moops::TraitFor::Keyword::rw" : {
         "file" : "lib/Moops/TraitFor/Keyword/rw.pm",
         "version" : "0.022"
      },
      "Moops::TraitFor::Keyword::rwp" : {
         "file" : "lib/Moops/TraitFor/Keyword/rwp.pm",
         "version" : "0.022"
      },
      "MooseX::FunctionParametersInfo" : {
         "file" : "lib/MooseX/FunctionParametersInfo.pm",
         "version" : "0.022"
      },
      "MooseX::FunctionParametersInfo::Trait::Method" : {
         "file" : "lib/MooseX/FunctionParametersInfo.pm",
         "version" : "0.022"
      },
      "MooseX::FunctionParametersInfo::Trait::WrappedMethod" : {
         "file" : "lib/MooseX/FunctionParametersInfo.pm",
         "version" : "0.022"
      },
      "PerlX::Assert" : {
         "file" : "lib/PerlX/Assert.pm",
         "version" : "0.022"
      },
      "PerlX::Define" : {
         "file" : "lib/PerlX/Define.pm",
         "version" : "0.022"
      }
   },
   "release_status" : "stable",
   "resources" : {
      "X_identifier" : "http://purl.org/NET/cpan-uri/dist/Moops/project",
      "bugtracker" : {
         "web" : "http://rt.cpan.org/Dist/Display.html?Queue=Moops"
      },
      "homepage" : "https://metacpan.org/release/Moops",
      "license" : [
         "http://dev.perl.org/licenses/"
      ],
      "repository" : {
         "type" : "git",
         "web" : "https://github.com/tobyink/p5-moops"
      }
   },
   "version" : "0.022"
}
END_META
Moops
=====

Created:      2013-06-30
Home page:    <https://metacpan.org/release/Moops>
Bug tracker:  <http://rt.cpan.org/Dist/Display.html?Queue=Moops>
Maintainer:   Toby Inkster (TOBYINK) <tobyink@cpan.org>

0.022	2013-09-16

 - Minor updates to work with Function::Parameters 1.0301.

0.021	2013-09-12

 - Allow version numbers to be specified for the `with`, `extends` and
   `types` options.

0.020	2013-09-11

 [ BACK COMPAT ]
 - Moops->import now takes a hash of options (including the `imports`
   option) rather than an arrayref of modules to import.

 [ Packaging ]
 - List Moose/Mouse/Moo/Class::Tiny dependencies as optional_features in
   META.json.

 [ Other ]
 - Improve Moops' extensibility via parser traits.

0.019	2013-08-30

 - Removed: Removed Class::Tiny::Antlers; this is now a separate CPAN
   distribution.

0.018	2013-08-27

 - Added: Add a `library` keyword for declaring type libraries.
 - Declared packages now get an implied BEGIN {...} block around
   themselves.

0.017	2013-08-21

 - Updated: Support Class::Tiny 0.004.

0.016	2013-08-21

 - Added: Provide a `types` option for loading type constraint libraries
   into classes, roles and namespaces.

0.015	2013-08-21

 [ Bug Fixes ]
 - Fix a reference to Moops::DefineKeyword which will only work if you
   happen to have installed Moops over the top of a pre-0.012 version of
   Moops.
 - Load feature.pm so that it's consistently exported to the outer scope.

0.014	2013-08-21

 [ Documentation ]
 - Document Class::Tiny::Antlers.

 [ Other ]
 - Added: MooseX::FunctionParametersInfo
 - Class::Tiny::Antlers now supports has \@attrs like Moose.

0.013	2013-08-20

 [ Bug Fixes ]
 - Fix test that uses Role::Tiny and Class::Tiny without declaring them
   (Test::Requires).

0.012	2013-08-20

 [ Documentation ]
 - Various documentation improvements.

 [ Other ]
 - Added: PerlX::Assert
 - Rename Moops::DefineKeyword -> PerlX::Define.

0.011	2013-08-20

 [ Documentation ]
 - Document Attribute::Handlers-style attributes as an extensibility
   mechanism.

 [ Other ]
 - Added: Class::Tiny::Antlers
 - Added: Moops::TraitFor::Keyword::dirty
 - Added: Moops::TraitFor::Keyword::mutable
 - Added: Moops::TraitFor::Keyword::ro
 - Added: Moops::TraitFor::Keyword::rw
 - Added: Moops::TraitFor::Keyword::rwp
 - Added: Support classes built `using Class::Tiny`.
 - Moose classes will now `use Moose::XSAccessor` if possible.
 - Use MooseX::MungeHas to 0.002 smooth over more differences between Moo,
   Mouse and Moose.

0.010	2013-08-19

 - Added: Parse Attribute::Handlers-style attributes attached to package
   declarations; treat these as traits for the code generator.
 - Much refactoring.
 - Rename Moops::CodeGenerator -> Moops::Keyword.

0.009	2013-08-19

 [ Bug Fixes ]
 - Fix at-runtime hook (used for method modifiers).

 [ Packaging ]
 - The test suite is now in a reasonable state.

0.008	2013-08-18

 [ Bug Fixes ]
 - Fix custom imports feature.
 - Found a remaining hard-coded list of keywords that was breaking
   extensibility mechanism.
 - Stop using constant.pm (though it's still required via Moo); this allows
   `true` and `false` to be correcting swept by namespace::sweep.

 [ Documentation ]
 - Bundle an example showing how to extend Moops.

 [ Packaging ]
 - Add Mouse and Moose as 'runtime suggests' dependencies.
 - Add Perl 5.14 as an explicit dependency.
 - More test suite improvements; still more to do.

0.007	2013-08-18

 [ Bug Fixes ]
 - Fix parsing for the `namespace` keyword that was broken in 0.005.

 [ Packaging ]
 - Dependency - runtime suggestion for MooX::HandlesVia.
 - More test suite improvements; still more to do.

 [ Other ]
 - Help Class::Load (and thus Moose) notice that empty roles are loaded by
   setting $VERSION to an empty string when no version is specified.

0.006	2013-08-16

 [ Documentation ]
 - Much improved documentation.

 [ Packaging ]
 - Some test suite improvements; more to come.

 [ Other ]
 - Call __PACKAGE__->meta->make_immutable on Moose/Mouse classes.
 - Rename MooX::Aspartame -> Moops.

0.005	2013-08-14

 [ REGRESSIONS ]
 - Broke `namespace` keyword.

 [ Other ]
 - Improvements handling comments when parsing.
 - Massive amounts of refactoring to simplify maintenance and make
   subclassing easier.

0.004	2013-08-14

 - Added: Implement `before`, `after` and `around` method modifiers.
 - Added: Implement `define` keyword to declare constants.
 - Removed: Drop the `classmethod` keyword; it's better to use `method` and
   give the invocant an explicit variable name.
 - Removed: Drop the `exporter` keyword; it is better to explicitly create
   a class extending Exporter::TypeTiny or Exporter.
 - The `method` keyword is only available in classes and roles; not plain
   namespaces.

0.003	2013-08-13

 [ Packaging ]
 - use Dist::Inkt.

 [ Other ]
 - Added: New keyword `namespace`.
 - Don't export Try::Tiny to the outer scope, as it's not lexical.
 - Misc internal refactoring.
 - Re-implement relative package names, in a new, saner way.
 - Updated: use Function::Parameters 1.0201, because it has configurable
   type constraint reification.

0.002	2013-07-17

 - Added: use MooX::late 0.014.
 - Misc internal refactoring.
 - Updated: use Moo 1.003000.

0.001	2013-07-01	Initial release
END_CHANGES
