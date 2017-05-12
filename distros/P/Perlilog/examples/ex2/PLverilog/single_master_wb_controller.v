// This is a generated file. Do not edit -- changes will be lost
// Created by Perlilog v0.3 on Tue Nov 11 19:42:08 2003
// Originating object: auto. gen. int. obj. 'single_master_wb_controller'

`timescale 1ns / 10ps

module single_master_wb_controller(m_wb_clk_i, m_wb_rst_i, m_wb_adr_o,
  m_wb_dat_o, m_wb_dat_i, m_wb_we_o, m_wb_stb_o, m_wb_cyc_o, m_wb_ack_i,
  wb_slave_adr, wb_slave_cyc, wb_slave_ack, wb_slave_dat, wb_slave_adr_1,
  wb_slave_cyc_1, wb_slave_ack_1, wb_slave_dat_1, wb_slave_adr_2,
  wb_slave_cyc_2, wb_slave_ack_2, wb_slave_dat_2);

  input  m_wb_clk_i;
  input  m_wb_rst_i;
  input [7:0] m_wb_adr_o;
  input [7:0] m_wb_dat_o;
  input  m_wb_we_o;
  input  m_wb_stb_o;
  input  m_wb_cyc_o;
  input  wb_slave_ack;
  input [7:0] wb_slave_dat;
  input  wb_slave_ack_1;
  input [7:0] wb_slave_dat_1;
  input  wb_slave_ack_2;
  input [7:0] wb_slave_dat_2;
  output [7:0] m_wb_dat_i;
  output  m_wb_ack_i;
  output [1:0] wb_slave_adr;
  output  wb_slave_cyc;
  output [1:0] wb_slave_adr_1;
  output  wb_slave_cyc_1;
  output [1:0] wb_slave_adr_2;
  output  wb_slave_cyc_2;
  wire  wb_slave_active;
  wire  wb_slave_active_1;
  wire  wb_slave_active_2;

  assign wb_slave_active = m_wb_adr_o[7:2] == 0;
  assign wb_slave_cyc = m_wb_cyc_o & wb_slave_active;
  assign wb_slave_adr = m_wb_adr_o[1:0];
  assign wb_slave_active_1 = m_wb_adr_o[7:2] == 1;
  assign wb_slave_cyc_1 = m_wb_cyc_o & wb_slave_active_1;
  assign wb_slave_adr_1 = m_wb_adr_o[1:0];
  assign wb_slave_active_2 = m_wb_adr_o[7:2] == 2;
  assign wb_slave_cyc_2 = m_wb_cyc_o & wb_slave_active_2;
  assign wb_slave_adr_2 = m_wb_adr_o[1:0];
  assign m_wb_ack_i = wb_slave_ack | wb_slave_ack_1 | wb_slave_ack_2;
  assign m_wb_dat_i = (wb_slave_active ? wb_slave_dat : 0) | (wb_slave_active_1 ? wb_slave_dat_1 : 0) | (wb_slave_active_2 ? wb_slave_dat_2 : 0);

endmodule
