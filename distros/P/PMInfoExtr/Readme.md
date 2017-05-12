#Perl Modules Extractor

Perl Modules Extractor is a tool to report which Perl Distributions and dependencies exist in a specific machine. That can be accomplished through several methods. Our approrach doesn't change any previously written code, therefore it uses Perl mechanisms to infer Perl Modules requirements.
The output format is JSON, which enables programming languages to easily extract the outputed data. For the Perl Modules Converter the Perl Modules and Distributions related data, can be extracted through JSON result key.


&nbsp;

## Usage Scenario##


The extractor should be placed in the target machine and executed through SSH Wrapper extractor. The aim of this Extractor is to report which Perl Modules and Distributions exist on the target machine. This revelated to be a complex problem, due to the multitude installation mechanism that Perl has to install Modules and Distributions. The Perl Modules extractor gathers information from several sources and tries to create an unified view.

&nbsp;

During the development phases, the extractor was tested on two Linux environments. The first a Caixa Magica 21, an Ubuntu based distribution, with kernel 2.11.09 and Perl Version 5.14.2. The second a Debian virtual machine with Phaidra. 

Regarding the requirements to execute Perl Extractor locally are:

1. Perl version > 5.10
2. Devel::Modlist (Perl Distribution)
3. File::Find::Rule (Perl Distribution)
4. JSON (Perl Distribution)
5. MetaCPAN::API (Perl Distribution)
6. Moose (Perl Distribution)
7. UUID::Tiny (Perl Distribution)


&nbsp;


##Distribution specific package Manager vs CPAN(m/p)

To install Perl Distributions is necessary to have a Perl Distribution Manager. In Linux, the dificulty is which one to choose. The three Perl Distribution packages are CPAN, CPAN Minus and CPAN Plus. If we count with the Linux Package Managers we end up with many more. Linux Package Managers don't have all CPAN Perl Distributions, hence using them to install all your dependencies can be a dreadfull experience. CPAN, CPAN Minus and CPAN Plus, all download and install distributions from [REF].

&nbsp;

## Usage Preconditions ##

###Perl Modules Requirements

[Devel::Modlist](https://metacpan.org/release/Devel-Modlist)

[File::Find::Rule](https://metacpan.org/release/File-Find-Rule)

[JSON](https://metacpan.org/release/JSON)

[MetaCPAN::API](https://metacpan.org/release/MetaCPAN-API)

[Moose](https://metacpan.org/release/Moose)

[UUID::Tiny](https://metacpan.org/release/UUID-Tiny)

&nbsp;

###Requirements Installion

	#!bash
	cpanp install Devel::Modlist
	cpanp install File::Find::Rule
	cpanp install JSON
	cpanp install Moose
	cpanp install UUID::Tiny

&nbsp;

####Recommended Perl Distribution

It is recommended to install [JSON::XS](https://metacpan.org/release/JSON-XS) to have a better JSON graphical visualization.

	#!bash
	cpanp install JSON::XS

&nbsp;

Development and testing has been performed on a x86_64 Linux environment with Perl v5.14.

&nbsp;

##Perl Modules Extractor Overview

Perl Modules Extractor has a well defined workflow, which is followed to give you a well formated report of which Perl Distributions exist on your system.
In the next paragraphs, each phase is explained briefly highlighting special key points to give you a broader insight of the tool.

&nbsp;

###Search Phase

During the first phase, Perl Module Extraction tool searches for files with extension "pm". When Perl searches for Modules it looks for them at specific folders. Those folders are pointed by a folder path array, which can be extracted by executing in a terminal:

	#!bash
	perl -V

Folders can be added to this array by passing a -I "path" to perl executable, on each execution. Inside Perl Virtual Machine, programmatically it is also possible to change that folder path array, however that is not adviced.

Perl Modules Extraction tool to be faster and also capture all pm files, only searches "pm" files in that folder path array. Each "pm" file is added to an array which will be consumed by Acquisition phase.

&nbsp;


###Acquisition Phase

Through Acquisition phase each file, previously gathered in the Search phase, is scanned for dependencies. Each dependency is inserted, as a key, in a hashtable so that we don't end up with duplicates. After acquiring all module dependencies, the control is passed to the analysis phase.

&nbsp;


###Analysis Phase

Using the keys from dependency modules hashtable, one by one is checked to which Distribution it belongs to. This check is performed through [MetaCPAN](https://metacpan.org/) REST API, which is mapped into [MetaCPAN::API](https://metacpan.org/release/MetaCPAN-API) Perl functions.

&nbsp;


###Reporting Phase

This module outputs each Distribution and its dependencies, found in previous phases (find, acquisition and analysis).

&nbsp;


##How to get the code ?

	#!bash
	git clone https://opensourceprojects.eu/git/p/timbus/context-population/extractors/local/perl-modules perl-modules

&nbsp;

##How to Execute

	#!bash
	perl test-modules.pl

&nbsp;

##Expected output

The Perl Modules output is JSON, and is printed in a single line. For a more visual comprehension is recommended to use the json_xs tool.

&nbsp;

###Example output

After a sucessfull Perl Information Extraction, is generated the file output.json. This file contains every information in a sigle line.


	#!JSON

	{
	   "format" : {
	      "id" : "d7f5e025-9daa-11e3-ab53-e3e54faab75e"
	   },
	   "result" : {
	      "machineUUID" : "",
	      "data" : {
	         "search_path" : [
	            "/home/nuno/perl5/lib/perl5/x86_64-linux-gnu-thread-multi",
	            "/home/nuno/perl5/lib/perl5",
	            "/etc/perl",
	            "/usr/local/lib/perl/5.14.2",
	            "/usr/local/share/perl/5.14.2",
	            "/usr/lib/perl5",
	            "/usr/share/perl5",
	            "/usr/lib/perl/5.14.2",
	            "/usr/lib/perl/5.14",
	            "/usr/share/perl/5.14.2",
	            "/usr/share/perl/5.14",
	            "/usr/local/lib/site_perl",
	            "/home/nuno/timbus/opensourceprojects/context-population/extractors/local/perl-modules"
	         ],
	        "distributions" : {
	            "audio-scrobbler" : {
	               "provides" : [
	                  "Audio::Scrobbler"
	               ],
	               "version" : "0.01-2.1",
	               "name" : "libaudio-scrobbler-perl",
	               "requirements" : [
	                  "libconfig-inifiles-perl",
	                  "libwww-perl",
	                  "perl (>= 5.6.0-16)"
	               ]
	            },
	            "aliased" : {
	               "provides" : null,
	               "version" : "0.31",
	               "name" : "aliased",
	               "requirements" : []
	            },
	            "xml-parser" : {
	               "provides" : [
	                  "XML::Parser",
	                  "XML::Parser::Style::Stream",
	                  "XML::Parser::Style::Tree",
	                  "XML::Parser::Style::Subs",
	                  "XML::Parser::Style::Objects",
	                  "XML::Parser::Style::Debug",
	                  "XML::Parser::Expat"
	               ],
	               "version" : "2.41-1build2",
	               "name" : "libxml-parser-perl",
	               "requirements" : [
	                  "perl (>= 5.14.2-13)",
	                  "perlapi-5.14.2",
	                  "liburi-perl",
	                  "libwww-perl",
	                  "libc6 (>= 2.14)",
	                  "libexpat1 (>= 2.0.1)"
	               ]
	            },
	            "Devel-Dependencies" : {
	               "provides" : [
	                  "Devel::Dependencies"
	               ],
	               "version" : "1.03",
	               "name" : "Devel-Dependencies",
	               "requirements" : [
	                  {
	                     "version" : "5.14.2-21build1",
	                     "name" : "perl"
	                  },
	                  {
	                     "version" : "5.14.2-21build1",
	                     "name" : "perl"
	                  }
	               ]
	            },
	            "Test-TCP" : {
	               "provides" : [
	                  "Test::TCP::CheckPort",
	                  "Test::TCP",
	                  "Net::EmptyPort"
	               ],
	               "version" : "2.02",
	               "name" : "Test-TCP",
	               "requirements" : [
	                  {
	                     "version" : "5.14.2-21build1",
	                     "name" : "perl"
	                  },
	                  {
	                     "version" : "5.14.2-21build1",
	                     "name" : "perl-modules"
	                  },
	                  {
	                     "version" : "5.14.2-21build1",
	                     "name" : "perl-base"
	                  },
	                  {
	                     "version" : "5.14.2-21build1",
	                     "name" : "perl"
	                  },
	                  {
	                     "version" : "0.23",
	                     "name" : "Test-SharedFork"
	                  }
	               ]
	            },
	            ...
	     },
	      "UUID" : "91dbaf55-b01c-11e3-9422-a58c1d99206b"
	   }
	}

&nbsp;

###Better visualization

For a better information visualization, is recommended to install JSON::XS and use it as follow:

	#!bash
	json_xs < output.json > output_pretty.json

Although the output.json content is the same as output_pretty.json, the latter is recommended for human readability.

&nbsp;

---

&nbsp;

## Output Description ##

On Phaidra installation, Perl Modules are being installed in a trial-error base. That manual effort to install all required Perl Modules, is impracticable. So, Perl Modules Extractor analyses all Perl Modules installed on a machine and detects which were its original Distribution. The excution is completely automatic and the outputed information is JSON, which is easily parsable from most languages. Altough it is similar to DPKG software, Perl has its specificities. Can be established a directional link between CPAN Distributions and DPKG Packages, however the oposite direction is not easily attainable.

[Link to the output ontology (output should be some kind of context relevant ontology!!!!!)](url)

### Generated Concepts and Properties###

Describe the generated output in terms of generated context model concepts and properties.

&nbsp;

### Mapping to TIMBUS DIO ###

Describe how the output relates to the TIMBUS Context Model and how it can be semantically included in the Context Model

&nbsp;

## TIMBUS Use Cases ##

### Use Case 1 (part of WP7) ###

Not all of the Perl modules can be installed using Linux package managers. Some of them are installed using CPAN. The tool detects Perl modules installed in the system by CPAN and stores them in the context model. The Perl modules installed using Linux package manager (e.g. aptitude) are not listed by the tool.

### Use Case 2 ###
To use the Perl Modules Extractor in the Phaidra use case is quite simple. It is only necessary to guarantee that all requirements (described in previous sections) are met, and the Perl Modules Extractor is on a file system folder. From there is possible to execute the Perl Modules extractor locally, using a shell or by using the SSH Wrapper Extractor.

The Perl Modules Extractor may receive input parameters on the console, or by through the SSH Wrapper Extractor Interface, which can output to Standard Error more information related with the extraction analysis. The extraction is only concluded when the output.json file is created, on the filesystem folder where the Perl Modules Extractor is.


&nbsp;

##Author

[Nuno Martins](https://metacpan.org/author/NUNOCMS) <nuno.martins@caixamagica.pt>

&nbsp;

# Changelog

Added Usage Scenario section 17/03/2014

Added Output Description - Relation between use case and extractor section 17/03/2014

Added Extraction Example 20/03/2014

&nbsp;

##License

Copyright (c) 2014, Caixa Magica Software Lda (CMS).
The work has been developed in the TIMBUS Project and the above-mentioned are Members of the TIMBUS Consortium.
TIMBUS is supported by the European Union under the 7th Framework Programme for research and technological development and demonstration activities (FP7/2007-2013) under grant agreement no. 269940.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at:   http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTIBITLY, or FITNESS FOR A PARTICULAR PURPOSE. In no event and under no legal theory, whether in tort (including negligence), contract, or otherwise, unless required by applicable law or agreed to in writing, shall any Contributor be liable for damages, including any direct, indirect, special, incidental, or consequential damages of any character arising as a result of this License or out of the use or inability to use the Work.
See the License for the specific language governing permissions and limitation under the License.
