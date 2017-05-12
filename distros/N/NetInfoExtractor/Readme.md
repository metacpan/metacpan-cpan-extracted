#Network Information

Network Information Extractor is a Perl script that extracts relevant configuration information and creates a JSON report file with that information.
This tool is useful to easily gather information that is disperse through virtual filesystems, and create a concise file with the relevant information. Moreover, it is also very useful to have all information gathered in one single file to restore all network configurations of a machine.

## Usage Scenario##

The extractor should be placed in the target machine and executed through SSH Wrapper extractor. The aim of this Extractor is to extract Network informations necessary to recreate the target machine.

&nbsp;

Altough this tool is for Linux devices, it only requires *ifconfig* to extract the IPv4 and IPv6 interface addresses. Any other obtained data is directly extracted from the Linux virtual filesystems *sys* and *proc*.
It was tested on Debian, Ubuntu and Redhat based distributions, using Kernels above 3.0 and Perl 5.10.

&nbsp;

##How to get the code

	git clone https://opensourceprojects.eu/git/p/timbus/context-population/extractors/local/network-info-perl network-info


&nbsp;

## Usage Preconditions ##

Tested Application Environments and Requirements
Operating Systems

###Requirements

1. [JSON Perl Distribution](https://metacpan.org/release/JSON)
2. [Moose Perl Distribution](https://metacpan.org/release/Moose)
3. [UUID::Tiny Distribution](https://metacpan.org/release/UUID-Tiny)
4. ifconfig tool

&nbsp;

####Install Requirements

	#!bash
	cpanp install Moose
	cpanp install JSON
	cpanp install UUID::Tiny

&nbsp;


##Collected Information

Network Information tool collects information about interfaces, route and nameservers.
Interfaces' information, except IPv4 and IPv6, is obtained from the sys virtual file system at **/sys/class/net/** folder. Each subfolder has the interface name its related files. Each file has the relevant data, such as: address (with mac address), mtu, speed, etc. Regarding the IPv4 and IPv6, it was gathered through **ifconfig** command.
In Linux the nameservers information is available in the file **/etc/resolv.conf**, therefore the nameserver key in the json is the content of that file.
As Interfaces' information is present in the sys file system, the routing information is present in the proc file system. The **/proc/net/route** file holds the Kernel information related to routing. The routes key in the json reflects the information present in that file.

&nbsp;

Altough the information, present in the json, is sufficient to have an accurate network view, we believe that a more thorough would have the bridges and firewall rules.

&nbsp;

##How to execute

	#!bash
	perl network-extractor.pl

&nbsp;

##Network information format

	format => id : "b744635a-9d6b-11e3-8ec0-da765d6aa4db",
	result => data => routes[]
				      => interfaces[]
				      => nameservers[]
		      => uuid: ""

&nbsp;

##Expected output

	#!json
	{
	   "format" : {
	      "id" : "b744635a-9d6b-11e3-8ec0-da765d6aa4db"
	   },
	   "result" : {
	      "data" : {
	         "routes" : [
	            {
	               "flags" : "0003",
	               "window" : "0",
	               "destination" : "0.0.0.0",
	               "gateway" : "##.##.##.###",
	               "metric" : "0",
	               "irtt" : "0",
	               "use" : "0",
	               "interface" : "eth0",
	               "refcnt" : "0",
	               "mask" : "0.0.0.0",
	               "mtu" : "0"
	            },
	            {
	               "flags" : "0001",
	               "window" : "0",
	               "destination" : "##.##.##.#",
	               "gateway" : "0.0.0.0",
	               "metric" : "1",
	               "irtt" : "0",
	               "use" : "0",
	               "interface" : "eth0",
	               "refcnt" : "0",
	               "mask" : "255.255.255.0",
	               "mtu" : "0"
	            }
	         ],
	         "network_interfaces" : [
	            {
	               "ipv6" : "fe80::f2de:####:####:####",
	               "macaddress" : "##:##:##:##:##:##",
	               "ipv4" : "##.##.##.##",
	               "speed" : "100",
	               "name" : "eth0",
	               "mtu" : "1500"
	            },
	            {
	               "ipv6" : "::1",
	               "macaddress" : "00:00:00:00:00:00",
	               "ipv4" : "127.0.0.1",
	               "speed" : null,
	               "name" : "lo",
	               "mtu" : "65536"
	            },
	         ],
	         "nameservers" : [
	            {
	               "search" : "caixamagica.pt",
	               "nameserver" : "127.0.1.1"
	            }
	         ],
	      },
	      "uuid" : "ccd60780-9d6b-11e3-9cc6-b01e563f1341"
	   }
	}


&nbsp;

## Output Description ##

The previous section presents the extraction output. That network extraction contains routing, interfaces and name servers. Each of these three categories has several data items with the relevant information, which can then be related in the converter.

&nbsp;

Using the network interfaces names and IP addresses together with the routes, it is possible to design how network data flows are exchanged. Adding name servers to previous information, we have a more detailed view of the network. All that information is relevant if it is necessary to rebuild the network environment of the target machine. If the information of all machines, in a network, is gathered we will have a very complete insight of the network. With such information, from link layer point of view, it would be possible to recreate almost the whole network.

&nbsp;

## TIMBUS Use Cases ##

Network Information Extraction can be used across use cases, however bear in mind it is specific for Linux platforms. If the Network Information Extractor is placed in the target system and all requirements (described in previous sections) are met, it is just necessary to execute the perl program.

To execute Network Information Extractor just:

	#!bash
	NETWORK_INFO_EXTRACTOR="target_folder";
	
	cd $NETWORK_INFO_EXTRACTOR/
	
	perl network_extractor.pl

&nbsp;

After the network_extractor execution is finished with success, the file **output.json** should be in the same folder where it was called. The output.json file has all information in a sigle line, so for an enhanced visualization experience it is advisable to use the json_xs tool.

&nbsp;

##Author

Nuno Martins <nuno.martins@caixamagica.pt>
&nbsp;

## Changelog ##

Added Usage Scenario section 18/03/2014

Added Output Description 18/03/2014

Added Timbus Use Cases 20/03/2014


&nbsp;

##License

Copyright (c) 2014, Caixa Magica Software Lda (CMS).
The work has been developed in the TIMBUS Project and the above-mentioned are Members of the TIMBUS Consortium.
TIMBUS is supported by the European Union under the 7th Framework Programme for research and technological development and demonstration activities (FP7/2007-2013) under grant agreement no. 269940.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at:   http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied, including without limitation, any warranties or conditions of TITLE, NON-INFRINGEMENT, MERCHANTIBITLY, or FITNESS FOR A PARTICULAR PURPOSE. In no event and under no legal theory, whether in tort (including negligence), contract, or otherwise, unless required by applicable law or agreed to in writing, shall any Contributor be liable for damages, including any direct, indirect, special, incidental, or consequential damages of any character arising as a result of this License or out of the use or inability to use the Work.
See the License for the specific language governing permissions and limitation under the License.