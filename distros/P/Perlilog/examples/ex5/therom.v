`timescale 1ns / 10ps

module rom2(zero, one, two, three);

   output [7:0] zero, one, two, three;

   assign zero  = 8'd65;
   assign one   = 8'd66;
   assign two   = 8'd67;
   assign three = 8'd10;
endmodule
