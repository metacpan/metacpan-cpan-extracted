#define PERL_constant_NOTFOUND	1
#define PERL_constant_NOTDEF	2
#define PERL_constant_ISIV	3
#define PERL_constant_ISNO	4
#define PERL_constant_ISNV	5
#define PERL_constant_ISPV	6
#define PERL_constant_ISPVN	7
#define PERL_constant_ISSV	8
#define PERL_constant_ISUNDEF	9
#define PERL_constant_ISUV	10
#define PERL_constant_ISYES	11

#ifndef NVTYPE
typedef double NV; /* 5.6 and later define NVTYPE, and typedef NV to it.  */
#endif
#ifndef aTHX_
#define aTHX_ /* 5.6 or later define this for threading support.  */
#endif
#ifndef pTHX_
#define pTHX_ /* 5.6 or later define this for threading support.  */
#endif

static int
constant_5 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BPF_A BPF_B BPF_H BPF_K BPF_W BPF_X */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'A':
    if (memEQ(name, "BPF_", 4)) {
    /*                   A     */
#ifdef BPF_A
      *iv_return = BPF_A;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "BPF_", 4)) {
    /*                   B     */
#ifdef BPF_B
      *iv_return = BPF_B;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "BPF_", 4)) {
    /*                   H     */
#ifdef BPF_H
      *iv_return = BPF_H;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "BPF_", 4)) {
    /*                   K     */
#ifdef BPF_K
      *iv_return = BPF_K;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "BPF_", 4)) {
    /*                   W     */
#ifdef BPF_W
      *iv_return = BPF_W;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "BPF_", 4)) {
    /*                   X     */
#ifdef BPF_X
      *iv_return = BPF_X;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_6 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BPF_JA BPF_LD BPF_OR BPF_ST */
  /* Offset 4 gives the best switch position.  */
  switch (name[4]) {
  case 'J':
    if (memEQ(name, "BPF_JA", 6)) {
    /*                   ^       */
#ifdef BPF_JA
      *iv_return = BPF_JA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "BPF_LD", 6)) {
    /*                   ^       */
#ifdef BPF_LD
      *iv_return = BPF_LD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "BPF_OR", 6)) {
    /*                   ^       */
#ifdef BPF_OR
      *iv_return = BPF_OR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "BPF_ST", 6)) {
    /*                   ^       */
#ifdef BPF_ST
      *iv_return = BPF_ST;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_7 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BPF_ABS BPF_ADD BPF_ALU BPF_AND BPF_DIV BPF_IMM BPF_IND BPF_JEQ BPF_JGE
     BPF_JGT BPF_JMP BPF_LDX BPF_LEN BPF_LSH BPF_MEM BPF_MSH BPF_MUL BPF_NEG
     BPF_RET BPF_RSH BPF_STX BPF_SUB BPF_TAX BPF_TXA DLT_ENC DLT_PPP DLT_RAW
     DLT_RIO */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'A':
    if (memEQ(name, "BPF_TX", 6)) {
    /*                     A     */
#ifdef BPF_TXA
      *iv_return = BPF_TXA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "BPF_SU", 6)) {
    /*                     B     */
#ifdef BPF_SUB
      *iv_return = BPF_SUB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "DLT_EN", 6)) {
    /*                     C     */
#ifdef DLT_ENC
      *iv_return = DLT_ENC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "BPF_AD", 6)) {
    /*                     D     */
#ifdef BPF_ADD
      *iv_return = BPF_ADD;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BPF_AN", 6)) {
    /*                     D     */
#ifdef BPF_AND
      *iv_return = BPF_AND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BPF_IN", 6)) {
    /*                     D     */
#ifdef BPF_IND
      *iv_return = BPF_IND;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "BPF_JG", 6)) {
    /*                     E     */
#ifdef BPF_JGE
      *iv_return = BPF_JGE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "BPF_NE", 6)) {
    /*                     G     */
#ifdef BPF_NEG
      *iv_return = BPF_NEG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "BPF_LS", 6)) {
    /*                     H     */
#ifdef BPF_LSH
      *iv_return = BPF_LSH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BPF_MS", 6)) {
    /*                     H     */
#ifdef BPF_MSH
      *iv_return = BPF_MSH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BPF_RS", 6)) {
    /*                     H     */
#ifdef BPF_RSH
      *iv_return = BPF_RSH;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "BPF_MU", 6)) {
    /*                     L     */
#ifdef BPF_MUL
      *iv_return = BPF_MUL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "BPF_IM", 6)) {
    /*                     M     */
#ifdef BPF_IMM
      *iv_return = BPF_IMM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BPF_ME", 6)) {
    /*                     M     */
#ifdef BPF_MEM
      *iv_return = BPF_MEM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "BPF_LE", 6)) {
    /*                     N     */
#ifdef BPF_LEN
      *iv_return = BPF_LEN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DLT_RI", 6)) {
    /*                     O     */
#ifdef DLT_RIO
      *iv_return = DLT_RIO;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "BPF_JM", 6)) {
    /*                     P     */
#ifdef BPF_JMP
      *iv_return = BPF_JMP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DLT_PP", 6)) {
    /*                     P     */
#ifdef DLT_PPP
      *iv_return = DLT_PPP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Q':
    if (memEQ(name, "BPF_JE", 6)) {
    /*                     Q     */
#ifdef BPF_JEQ
      *iv_return = BPF_JEQ;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "BPF_AB", 6)) {
    /*                     S     */
#ifdef BPF_ABS
      *iv_return = BPF_ABS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "BPF_JG", 6)) {
    /*                     T     */
#ifdef BPF_JGT
      *iv_return = BPF_JGT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BPF_RE", 6)) {
    /*                     T     */
#ifdef BPF_RET
      *iv_return = BPF_RET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "BPF_AL", 6)) {
    /*                     U     */
#ifdef BPF_ALU
      *iv_return = BPF_ALU;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'V':
    if (memEQ(name, "BPF_DI", 6)) {
    /*                     V     */
#ifdef BPF_DIV
      *iv_return = BPF_DIV;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'W':
    if (memEQ(name, "DLT_RA", 6)) {
    /*                     W     */
#ifdef DLT_RAW
      *iv_return = DLT_RAW;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "BPF_LD", 6)) {
    /*                     X     */
#ifdef BPF_LDX
      *iv_return = BPF_LDX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BPF_ST", 6)) {
    /*                     X     */
#ifdef BPF_STX
      *iv_return = BPF_STX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BPF_TA", 6)) {
    /*                     X     */
#ifdef BPF_TAX
      *iv_return = BPF_TAX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_8 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BPF_JSET BPF_MISC DLT_AX25 DLT_FDDI DLT_LOOP DLT_NULL DLT_SLIP DLT_TZSP
     MODE_MON */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'D':
    if (memEQ(name, "DLT_FDDI", 8)) {
    /*                    ^        */
#ifdef DLT_FDDI
      *iv_return = DLT_FDDI;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "BPF_MISC", 8)) {
    /*                    ^        */
#ifdef BPF_MISC
      *iv_return = BPF_MISC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "DLT_SLIP", 8)) {
    /*                    ^        */
#ifdef DLT_SLIP
      *iv_return = DLT_SLIP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "MODE_MON", 8)) {
    /*                    ^        */
#ifdef MODE_MON
      *iv_return = MODE_MON;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DLT_LOOP", 8)) {
    /*                    ^        */
#ifdef DLT_LOOP
      *iv_return = DLT_LOOP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "BPF_JSET", 8)) {
    /*                    ^        */
#ifdef BPF_JSET
      *iv_return = BPF_JSET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "DLT_NULL", 8)) {
    /*                    ^        */
#ifdef DLT_NULL
      *iv_return = DLT_NULL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'X':
    if (memEQ(name, "DLT_AX25", 8)) {
    /*                    ^        */
#ifdef DLT_AX25
      *iv_return = DLT_AX25;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Z':
    if (memEQ(name, "DLT_TZSP", 8)) {
    /*                    ^        */
#ifdef DLT_TZSP
      *iv_return = DLT_TZSP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_9 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DLT_CHAOS DLT_CHDLC DLT_EN3MB DLT_HHDLC DLT_LTALK DLT_PFLOG DLT_USER0
     DLT_USER1 DLT_USER2 DLT_USER3 DLT_USER4 DLT_USER5 DLT_USER6 DLT_USER7
     DLT_USER8 DLT_USER9 MODE_CAPT MODE_STAT */
  /* Offset 8 gives the best switch position.  */
  switch (name[8]) {
  case '0':
    if (memEQ(name, "DLT_USER", 8)) {
    /*                       0     */
#ifdef DLT_USER0
      *iv_return = DLT_USER0;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '1':
    if (memEQ(name, "DLT_USER", 8)) {
    /*                       1     */
#ifdef DLT_USER1
      *iv_return = DLT_USER1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "DLT_USER", 8)) {
    /*                       2     */
#ifdef DLT_USER2
      *iv_return = DLT_USER2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "DLT_USER", 8)) {
    /*                       3     */
#ifdef DLT_USER3
      *iv_return = DLT_USER3;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "DLT_USER", 8)) {
    /*                       4     */
#ifdef DLT_USER4
      *iv_return = DLT_USER4;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '5':
    if (memEQ(name, "DLT_USER", 8)) {
    /*                       5     */
#ifdef DLT_USER5
      *iv_return = DLT_USER5;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '6':
    if (memEQ(name, "DLT_USER", 8)) {
    /*                       6     */
#ifdef DLT_USER6
      *iv_return = DLT_USER6;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '7':
    if (memEQ(name, "DLT_USER", 8)) {
    /*                       7     */
#ifdef DLT_USER7
      *iv_return = DLT_USER7;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '8':
    if (memEQ(name, "DLT_USER", 8)) {
    /*                       8     */
#ifdef DLT_USER8
      *iv_return = DLT_USER8;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '9':
    if (memEQ(name, "DLT_USER", 8)) {
    /*                       9     */
#ifdef DLT_USER9
      *iv_return = DLT_USER9;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "DLT_EN3M", 8)) {
    /*                       B     */
#ifdef DLT_EN3MB
      *iv_return = DLT_EN3MB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "DLT_CHDL", 8)) {
    /*                       C     */
#ifdef DLT_CHDLC
      *iv_return = DLT_CHDLC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DLT_HHDL", 8)) {
    /*                       C     */
#ifdef DLT_HHDLC
      *iv_return = DLT_HHDLC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "DLT_PFLO", 8)) {
    /*                       G     */
#ifdef DLT_PFLOG
      *iv_return = DLT_PFLOG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'K':
    if (memEQ(name, "DLT_LTAL", 8)) {
    /*                       K     */
#ifdef DLT_LTALK
      *iv_return = DLT_LTALK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DLT_CHAO", 8)) {
    /*                       S     */
#ifdef DLT_CHAOS
      *iv_return = DLT_CHAOS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "MODE_CAP", 8)) {
    /*                       T     */
#ifdef MODE_CAPT
      *iv_return = MODE_CAPT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "MODE_STA", 8)) {
    /*                       T     */
#ifdef MODE_STAT
      *iv_return = MODE_STAT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_10 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DLT_ARCNET DLT_AURORA DLT_C_HDLC DLT_DOCSIS DLT_ECONET DLT_EN10MB
     DLT_FRELAY DLT_IBM_SN DLT_IBM_SP DLT_PFSYNC DLT_PRONET DLT_SUNATM
     DLT_USER10 DLT_USER11 DLT_USER12 DLT_USER13 DLT_USER14 DLT_USER15 */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case '0':
    if (memEQ(name, "DLT_USER1", 9)) {
    /*                        0     */
#ifdef DLT_USER10
      *iv_return = DLT_USER10;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '1':
    if (memEQ(name, "DLT_USER1", 9)) {
    /*                        1     */
#ifdef DLT_USER11
      *iv_return = DLT_USER11;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '2':
    if (memEQ(name, "DLT_USER1", 9)) {
    /*                        2     */
#ifdef DLT_USER12
      *iv_return = DLT_USER12;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '3':
    if (memEQ(name, "DLT_USER1", 9)) {
    /*                        3     */
#ifdef DLT_USER13
      *iv_return = DLT_USER13;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '4':
    if (memEQ(name, "DLT_USER1", 9)) {
    /*                        4     */
#ifdef DLT_USER14
      *iv_return = DLT_USER14;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '5':
    if (memEQ(name, "DLT_USER1", 9)) {
    /*                        5     */
#ifdef DLT_USER15
      *iv_return = DLT_USER15;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'A':
    if (memEQ(name, "DLT_AUROR", 9)) {
    /*                        A     */
#ifdef DLT_AURORA
      *iv_return = DLT_AURORA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'B':
    if (memEQ(name, "DLT_EN10M", 9)) {
    /*                        B     */
#ifdef DLT_EN10MB
      *iv_return = DLT_EN10MB;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'C':
    if (memEQ(name, "DLT_C_HDL", 9)) {
    /*                        C     */
#ifdef DLT_C_HDLC
      *iv_return = DLT_C_HDLC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DLT_PFSYN", 9)) {
    /*                        C     */
#ifdef DLT_PFSYNC
      *iv_return = DLT_PFSYNC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'M':
    if (memEQ(name, "DLT_SUNAT", 9)) {
    /*                        M     */
#ifdef DLT_SUNATM
      *iv_return = DLT_SUNATM;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "DLT_IBM_S", 9)) {
    /*                        N     */
#ifdef DLT_IBM_SN
      *iv_return = DLT_IBM_SN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "DLT_IBM_S", 9)) {
    /*                        P     */
#ifdef DLT_IBM_SP
      *iv_return = DLT_IBM_SP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DLT_DOCSI", 9)) {
    /*                        S     */
#ifdef DLT_DOCSIS
      *iv_return = DLT_DOCSIS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DLT_ARCNE", 9)) {
    /*                        T     */
#ifdef DLT_ARCNET
      *iv_return = DLT_ARCNET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DLT_ECONE", 9)) {
    /*                        T     */
#ifdef DLT_ECONET
      *iv_return = DLT_ECONET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DLT_PRONE", 9)) {
    /*                        T     */
#ifdef DLT_PRONET
      *iv_return = DLT_PRONET;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'Y':
    if (memEQ(name, "DLT_FRELA", 9)) {
    /*                        Y     */
#ifdef DLT_FRELAY
      *iv_return = DLT_FRELAY;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_11 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BPF_RELEASE DLT_IEEE802 DLT_PCI_EXP */
  /* Offset 6 gives the best switch position.  */
  switch (name[6]) {
  case 'E':
    if (memEQ(name, "DLT_IEEE802", 11)) {
    /*                     ^           */
#ifdef DLT_IEEE802
      *iv_return = DLT_IEEE802;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "DLT_PCI_EXP", 11)) {
    /*                     ^           */
#ifdef DLT_PCI_EXP
      *iv_return = DLT_PCI_EXP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "BPF_RELEASE", 11)) {
    /*                     ^           */
#ifdef BPF_RELEASE
      *iv_return = BPF_RELEASE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_12 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BPF_MAXINSNS BPF_MEMWORDS DLT_ATM_CLIP DLT_IPFILTER */
  /* Offset 9 gives the best switch position.  */
  switch (name[9]) {
  case 'L':
    if (memEQ(name, "DLT_ATM_CLIP", 12)) {
    /*                        ^         */
#ifdef DLT_ATM_CLIP
      *iv_return = DLT_ATM_CLIP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'R':
    if (memEQ(name, "BPF_MEMWORDS", 12)) {
    /*                        ^         */
#ifdef BPF_MEMWORDS
      *iv_return = BPF_MEMWORDS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "BPF_MAXINSNS", 12)) {
    /*                        ^         */
#ifdef BPF_MAXINSNS
      *iv_return = BPF_MAXINSNS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DLT_IPFILTER", 12)) {
    /*                        ^         */
#ifdef DLT_IPFILTER
      *iv_return = DLT_IPFILTER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_13 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BPF_ALIGNMENT DLT_CISCO_IOS DLT_LINUX_SLL DLT_OLD_PFLOG DLT_PPP_BSDOS
     DLT_PPP_ETHER */
  /* Offset 10 gives the best switch position.  */
  switch (name[10]) {
  case 'D':
    if (memEQ(name, "DLT_PPP_BSDOS", 13)) {
    /*                         ^         */
#ifdef DLT_PPP_BSDOS
      *iv_return = DLT_PPP_BSDOS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "BPF_ALIGNMENT", 13)) {
    /*                         ^         */
#ifdef BPF_ALIGNMENT
      *iv_return = BPF_ALIGNMENT;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'H':
    if (memEQ(name, "DLT_PPP_ETHER", 13)) {
    /*                         ^         */
#ifdef DLT_PPP_ETHER
      *iv_return = DLT_PPP_ETHER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "DLT_CISCO_IOS", 13)) {
    /*                         ^         */
#ifdef DLT_CISCO_IOS
      *iv_return = DLT_CISCO_IOS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "DLT_OLD_PFLOG", 13)) {
    /*                         ^         */
#ifdef DLT_OLD_PFLOG
      *iv_return = DLT_OLD_PFLOG;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'S':
    if (memEQ(name, "DLT_LINUX_SLL", 13)) {
    /*                         ^         */
#ifdef DLT_LINUX_SLL
      *iv_return = DLT_LINUX_SLL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_14 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BPF_MAXBUFSIZE BPF_MINBUFSIZE DLT_IEEE802_11 DLT_IP_OVER_FC DLT_JUNIPER_ES
     DLT_LINUX_IRDA DLT_PPP_SERIAL DLT_SLIP_BSDOS */
  /* Offset 7 gives the best switch position.  */
  switch (name[7]) {
  case 'B':
    if (memEQ(name, "BPF_MAXBUFSIZE", 14)) {
    /*                      ^             */
#ifdef BPF_MAXBUFSIZE
      *iv_return = BPF_MAXBUFSIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "BPF_MINBUFSIZE", 14)) {
    /*                      ^             */
#ifdef BPF_MINBUFSIZE
      *iv_return = BPF_MINBUFSIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'E':
    if (memEQ(name, "DLT_IEEE802_11", 14)) {
    /*                      ^             */
#ifdef DLT_IEEE802_11
      *iv_return = DLT_IEEE802_11;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "DLT_JUNIPER_ES", 14)) {
    /*                      ^             */
#ifdef DLT_JUNIPER_ES
      *iv_return = DLT_JUNIPER_ES;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'O':
    if (memEQ(name, "DLT_IP_OVER_FC", 14)) {
    /*                      ^             */
#ifdef DLT_IP_OVER_FC
      *iv_return = DLT_IP_OVER_FC;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'P':
    if (memEQ(name, "DLT_SLIP_BSDOS", 14)) {
    /*                      ^             */
#ifdef DLT_SLIP_BSDOS
      *iv_return = DLT_SLIP_BSDOS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "DLT_LINUX_IRDA", 14)) {
    /*                      ^             */
#ifdef DLT_LINUX_IRDA
      *iv_return = DLT_LINUX_IRDA;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case '_':
    if (memEQ(name, "DLT_PPP_SERIAL", 14)) {
    /*                      ^             */
#ifdef DLT_PPP_SERIAL
      *iv_return = DLT_PPP_SERIAL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_16 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DLT_ARCNET_LINUX DLT_JUNIPER_ATM1 DLT_JUNIPER_ATM2 DLT_JUNIPER_GGSN
     DLT_JUNIPER_MLFR DLT_PRISM_HEADER PCAP_ERRBUF_SIZE PCAP_IF_LOOPBACK */
  /* Offset 13 gives the best switch position.  */
  switch (name[13]) {
  case 'A':
    if (memEQ(name, "PCAP_IF_LOOPBACK", 16)) {
    /*                            ^         */
#ifdef PCAP_IF_LOOPBACK
      *iv_return = PCAP_IF_LOOPBACK;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'D':
    if (memEQ(name, "DLT_PRISM_HEADER", 16)) {
    /*                            ^         */
#ifdef DLT_PRISM_HEADER
      *iv_return = DLT_PRISM_HEADER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'G':
    if (memEQ(name, "DLT_JUNIPER_GGSN", 16)) {
    /*                            ^         */
#ifdef DLT_JUNIPER_GGSN
      *iv_return = DLT_JUNIPER_GGSN;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "PCAP_ERRBUF_SIZE", 16)) {
    /*                            ^         */
#ifdef PCAP_ERRBUF_SIZE
      *iv_return = PCAP_ERRBUF_SIZE;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'L':
    if (memEQ(name, "DLT_JUNIPER_MLFR", 16)) {
    /*                            ^         */
#ifdef DLT_JUNIPER_MLFR
      *iv_return = DLT_JUNIPER_MLFR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "DLT_ARCNET_LINUX", 16)) {
    /*                            ^         */
#ifdef DLT_ARCNET_LINUX
      *iv_return = DLT_ARCNET_LINUX;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'T':
    if (memEQ(name, "DLT_JUNIPER_ATM1", 16)) {
    /*                            ^         */
#ifdef DLT_JUNIPER_ATM1
      *iv_return = DLT_JUNIPER_ATM1;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    if (memEQ(name, "DLT_JUNIPER_ATM2", 16)) {
    /*                            ^         */
#ifdef DLT_JUNIPER_ATM2
      *iv_return = DLT_JUNIPER_ATM2;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_17 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     BPF_MAJOR_VERSION BPF_MINOR_VERSION DLT_JUNIPER_MLPPP */
  /* Offset 5 gives the best switch position.  */
  switch (name[5]) {
  case 'A':
    if (memEQ(name, "BPF_MAJOR_VERSION", 17)) {
    /*                    ^                  */
#ifdef BPF_MAJOR_VERSION
      *iv_return = BPF_MAJOR_VERSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'I':
    if (memEQ(name, "BPF_MINOR_VERSION", 17)) {
    /*                    ^                  */
#ifdef BPF_MINOR_VERSION
      *iv_return = BPF_MINOR_VERSION;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'U':
    if (memEQ(name, "DLT_JUNIPER_MLPPP", 17)) {
    /*                    ^                  */
#ifdef DLT_JUNIPER_MLPPP
      *iv_return = DLT_JUNIPER_MLPPP;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant_18 (pTHX_ const char *name, IV *iv_return) {
  /* When generated this function returned values for the list of names given
     here.  However, subsequent manual editing may have added or removed some.
     DLT_AIRONET_HEADER PCAP_VERSION_MAJOR PCAP_VERSION_MINOR */
  /* Offset 15 gives the best switch position.  */
  switch (name[15]) {
  case 'D':
    if (memEQ(name, "DLT_AIRONET_HEADER", 18)) {
    /*                              ^         */
#ifdef DLT_AIRONET_HEADER
      *iv_return = DLT_AIRONET_HEADER;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'J':
    if (memEQ(name, "PCAP_VERSION_MAJOR", 18)) {
    /*                              ^         */
#ifdef PCAP_VERSION_MAJOR
      *iv_return = PCAP_VERSION_MAJOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 'N':
    if (memEQ(name, "PCAP_VERSION_MINOR", 18)) {
    /*                              ^         */
#ifdef PCAP_VERSION_MINOR
      *iv_return = PCAP_VERSION_MINOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

static int
constant (pTHX_ const char *name, STRLEN len, IV *iv_return) {
  /* Initially switch on the length of the name.  */
  /* When generated this function returned values for the list of names given
     in this section of perl code.  Rather than manually editing these functions
     to add or remove constants, which would result in this comment and section
     of code becoming inaccurate, we recommend that you edit this section of
     code, and use it to regenerate a new set of constant functions which you
     then use to replace the originals.

     Regenerate these constant functions by feeding this entire source file to
     perl -x

#!/usr/bin/perl5.8.5 -w
use ExtUtils::Constant qw (constant_types C_constant XS_constant);

my $types = {map {($_, 1)} qw(IV)};
my @names = (qw(BPF_A BPF_ABS BPF_ADD BPF_ALIGNMENT BPF_ALU BPF_AND BPF_B
	       BPF_DIV BPF_H BPF_IMM BPF_IND BPF_JA BPF_JEQ BPF_JGE BPF_JGT
	       BPF_JMP BPF_JSET BPF_K BPF_LD BPF_LDX BPF_LEN BPF_LSH
	       BPF_MAJOR_VERSION BPF_MAXBUFSIZE BPF_MAXINSNS BPF_MEM
	       BPF_MEMWORDS BPF_MINBUFSIZE BPF_MINOR_VERSION BPF_MISC BPF_MSH
	       BPF_MUL BPF_NEG BPF_OR BPF_RELEASE BPF_RET BPF_RSH BPF_ST
	       BPF_STX BPF_SUB BPF_TAX BPF_TXA BPF_W BPF_X DLT_AIRONET_HEADER
	       DLT_APPLE_IP_OVER_IEEE1394 DLT_ARCNET DLT_ARCNET_LINUX
	       DLT_ATM_CLIP DLT_ATM_RFC1483 DLT_AURORA DLT_AX25 DLT_CHAOS
	       DLT_CHDLC DLT_CISCO_IOS DLT_C_HDLC DLT_DOCSIS DLT_ECONET
	       DLT_EN10MB DLT_EN3MB DLT_ENC DLT_FDDI DLT_FRELAY DLT_HHDLC
	       DLT_IBM_SN DLT_IBM_SP DLT_IEEE802 DLT_IEEE802_11
	       DLT_IEEE802_11_RADIO DLT_IEEE802_11_RADIO_AVS DLT_IPFILTER
	       DLT_IP_OVER_FC DLT_JUNIPER_ATM1 DLT_JUNIPER_ATM2 DLT_JUNIPER_ES
	       DLT_JUNIPER_GGSN DLT_JUNIPER_MFR DLT_JUNIPER_MLFR
	       DLT_JUNIPER_MLPPP DLT_JUNIPER_MONITOR DLT_JUNIPER_SERVICES
	       DLT_LINUX_IRDA DLT_LINUX_SLL DLT_LOOP DLT_LTALK DLT_NULL
	       DLT_OLD_PFLOG DLT_PCI_EXP DLT_PFLOG DLT_PFSYNC DLT_PPP
	       DLT_PPP_BSDOS DLT_PPP_ETHER DLT_PPP_SERIAL DLT_PRISM_HEADER
	       DLT_PRONET DLT_RAW DLT_RIO DLT_SLIP DLT_SLIP_BSDOS DLT_SUNATM
	       DLT_SYMANTEC_FIREWALL DLT_TZSP DLT_USER0 DLT_USER1 DLT_USER10
	       DLT_USER11 DLT_USER12 DLT_USER13 DLT_USER14 DLT_USER15 DLT_USER2
	       DLT_USER3 DLT_USER4 DLT_USER5 DLT_USER6 DLT_USER7 DLT_USER8
	       DLT_USER9 MODE_CAPT MODE_MON MODE_STAT PCAP_ERRBUF_SIZE
	       PCAP_IF_LOOPBACK PCAP_VERSION_MAJOR PCAP_VERSION_MINOR));

print constant_types(); # macro defs
foreach (C_constant ("pcap", 'constant', 'IV', $types, undef, 3, @names) ) {
    print $_, "\n"; # C constant subs
}
print "#### XS Section:\n";
print XS_constant ("pcap", $types);
__END__
   */

  switch (len) {
  case 5:
    return constant_5 (aTHX_ name, iv_return);
    break;
  case 6:
    return constant_6 (aTHX_ name, iv_return);
    break;
  case 7:
    return constant_7 (aTHX_ name, iv_return);
    break;
  case 8:
    return constant_8 (aTHX_ name, iv_return);
    break;
  case 9:
    return constant_9 (aTHX_ name, iv_return);
    break;
  case 10:
    return constant_10 (aTHX_ name, iv_return);
    break;
  case 11:
    return constant_11 (aTHX_ name, iv_return);
    break;
  case 12:
    return constant_12 (aTHX_ name, iv_return);
    break;
  case 13:
    return constant_13 (aTHX_ name, iv_return);
    break;
  case 14:
    return constant_14 (aTHX_ name, iv_return);
    break;
  case 15:
    /* Names all of length 15.  */
    /* DLT_ATM_RFC1483 DLT_JUNIPER_MFR */
    /* Offset 5 gives the best switch position.  */
    switch (name[5]) {
    case 'T':
      if (memEQ(name, "DLT_ATM_RFC1483", 15)) {
      /*                    ^                */
#ifdef DLT_ATM_RFC1483
        *iv_return = DLT_ATM_RFC1483;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'U':
      if (memEQ(name, "DLT_JUNIPER_MFR", 15)) {
      /*                    ^                */
#ifdef DLT_JUNIPER_MFR
        *iv_return = DLT_JUNIPER_MFR;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 16:
    return constant_16 (aTHX_ name, iv_return);
    break;
  case 17:
    return constant_17 (aTHX_ name, iv_return);
    break;
  case 18:
    return constant_18 (aTHX_ name, iv_return);
    break;
  case 19:
    if (memEQ(name, "DLT_JUNIPER_MONITOR", 19)) {
#ifdef DLT_JUNIPER_MONITOR
      *iv_return = DLT_JUNIPER_MONITOR;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 20:
    /* Names all of length 20.  */
    /* DLT_IEEE802_11_RADIO DLT_JUNIPER_SERVICES */
    /* Offset 4 gives the best switch position.  */
    switch (name[4]) {
    case 'I':
      if (memEQ(name, "DLT_IEEE802_11_RADIO", 20)) {
      /*                   ^                      */
#ifdef DLT_IEEE802_11_RADIO
        *iv_return = DLT_IEEE802_11_RADIO;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    case 'J':
      if (memEQ(name, "DLT_JUNIPER_SERVICES", 20)) {
      /*                   ^                      */
#ifdef DLT_JUNIPER_SERVICES
        *iv_return = DLT_JUNIPER_SERVICES;
        return PERL_constant_ISIV;
#else
        return PERL_constant_NOTDEF;
#endif
      }
      break;
    }
    break;
  case 21:
    if (memEQ(name, "DLT_SYMANTEC_FIREWALL", 21)) {
#ifdef DLT_SYMANTEC_FIREWALL
      *iv_return = DLT_SYMANTEC_FIREWALL;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 24:
    if (memEQ(name, "DLT_IEEE802_11_RADIO_AVS", 24)) {
#ifdef DLT_IEEE802_11_RADIO_AVS
      *iv_return = DLT_IEEE802_11_RADIO_AVS;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  case 26:
    if (memEQ(name, "DLT_APPLE_IP_OVER_IEEE1394", 26)) {
#ifdef DLT_APPLE_IP_OVER_IEEE1394
      *iv_return = DLT_APPLE_IP_OVER_IEEE1394;
      return PERL_constant_ISIV;
#else
      return PERL_constant_NOTDEF;
#endif
    }
    break;
  }
  return PERL_constant_NOTFOUND;
}

