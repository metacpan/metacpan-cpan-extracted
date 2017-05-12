
# This example shows how to generate multiple node with a single command.

PbsUse 'Builders/MultiNodeBuilder' ;

AddRule [VIRTUAL], "all",['all' => 'A', 'A_B', 'A_C', 'C'], BuildOk() ;

AddRule "A_or_B", [qr/A/] =>
	[
	  "echo hip hop la"
	, "ls /root"
	, "xtouch %FILE_TO_BUILD"
        ] ;

AddRule "C", [qr/C/] =>
	[
	  "echo building C"
        ] ;
