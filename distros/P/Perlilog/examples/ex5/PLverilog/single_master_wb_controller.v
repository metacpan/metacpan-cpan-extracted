`timescale 1ns / 10ps

module single_master_wb_controller(m_wb_clk_i, m_wb_rst_i, m_wb_adr_o,
  m_wb_dat_o, m_wb_dat_i, m_wb_we_o, m_wb_stb_o, m_wb_cyc_o, m_wb_ack_i,
  wb_slave_adr, wb_slave_cyc, wb_slave_ack, wb_slave_dat, wb_clk_i, wb_rst_i,
  wb_dat_i, wb_we_i, wb_stb_i, zero, one, two, three);

  input  m_wb_clk_i;
  input  m_wb_rst_i;
  input [7:0] m_wb_adr_o;
  input [7:0] m_wb_dat_o;
  input  m_wb_we_o;
  input  m_wb_stb_o;
  input  m_wb_cyc_o;
  input  wb_slave_ack;
  input [7:0] wb_slave_dat;
  input  wb_clk_i;
  input  wb_rst_i;
  input [7:0] wb_dat_i;
  input  wb_we_i;
  input  wb_stb_i;
  input [7:0] zero;
  input [7:0] one;
  input [7:0] two;
  input [7:0] three;
  output [7:0] m_wb_dat_i;
  output  m_wb_ack_i;
  output [1:0] wb_slave_adr;
  output  wb_slave_cyc;
  reg [7:0] wb_dat_o;
  wire  wb_slave_active;
  wire [1:0] wb_slave_adr_1;
  wire  wb_slave_cyc_1;
  wire  wb_slave_ack_1;
  wire  wb_slave_active_1;
  wire [7:0] wb_slave_dat_1;
  wire [1:0] wb_adr_i;
  wire  wb_cyc_i;
  wire  wb_ack_o;

  assign wb_slave_active = m_wb_adr_o[7:2] == 0;
  assign wb_slave_cyc = m_wb_cyc_o & wb_slave_active;
  assign wb_slave_adr = m_wb_adr_o[1:0];
  assign wb_slave_active_1 = m_wb_adr_o[7:2] == 1;
  assign wb_slave_cyc_1 = m_wb_cyc_o & wb_slave_active_1;
  assign wb_slave_adr_1 = m_wb_adr_o[1:0];
  assign m_wb_ack_i = wb_slave_ack | wb_slave_ack_1;
  assign m_wb_dat_i = (wb_slave_active ? wb_slave_dat : 0) | (wb_slave_active_1 ? wb_slave_dat_1 : 0);
  assign wb_ack_o = wb_cyc_i && wb_stb_i;
  always @(wb_adr_i or zero or one or two or three)
    case (wb_adr_i)
      0: wb_dat_o = zero;
      1: wb_dat_o = one;
      2: wb_dat_o = two;
      3: wb_dat_o = three;
      default: wb_dat_o = 0;
    endcase

  assign wb_adr_i = wb_slave_adr_1;
  assign wb_cyc_i = wb_slave_cyc_1;
  assign wb_slave_ack_1 = wb_ack_o;
  assign wb_slave_dat_1 = wb_dat_o;

endmodule
