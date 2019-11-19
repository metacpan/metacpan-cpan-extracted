#pragma once

#define IS_CREATE(p) ( \
  p[0] == 'C' &&        \
  p[1] == 'R' &&        \
  p[2] == 'E' &&        \
  p[3] == 'A' &&        \
  p[4] == 'T' &&        \
  p[5] == 'E'           \
)

#define IS_TABLE(p) (   \
  p[0] == 'T' &&        \
  p[1] == 'A' &&        \
  p[2] == 'B' &&        \
  p[3] == 'L' &&        \
  p[4] == 'E'           \
)

#define IS_INSERT(p) ( \
  p[0] == 'I' &&        \
  p[1] == 'N' &&        \
  p[2] == 'S' &&        \
  p[3] == 'E' &&        \
  p[4] == 'R' &&        \
  p[5] == 'T'           \
)

#define IS_INTO(p) (   \
  p[0] == 'I' &&        \
  p[1] == 'N' &&        \
  p[2] == 'T' &&        \
  p[3] == 'O'           \
)

#define IS_VALUES(p) ( \
  p[0] == 'V' &&        \
  p[1] == 'A' &&        \
  p[2] == 'L' &&        \
  p[3] == 'U' &&        \
  p[4] == 'E' &&        \
  p[5] == 'S'           \
)

#define IS_KEY(p) (     \
  p[0] == 'K' &&        \
  p[1] == 'E' &&        \
  p[2] == 'Y'           \
)

#define IS_INDEX(p) (   \
  p[0] == 'I' &&        \
  p[1] == 'N' &&        \
  p[2] == 'D' &&        \
  p[3] == 'E' &&        \
  p[4] == 'X'           \
)

#define IS_UNIQUE(p) ( \
  p[0] == 'U' &&        \
  p[1] == 'N' &&        \
  p[2] == 'I' &&        \
  p[3] == 'Q' &&        \
  p[4] == 'U' &&        \
  p[5] == 'E'           \
)

#define IS_PRIMARY(p) ( \
  p[0] == 'P' &&         \
  p[1] == 'R' &&         \
  p[2] == 'I' &&         \
  p[3] == 'M' &&         \
  p[4] == 'A' &&         \
  p[5] == 'R' &&         \
  p[6] == 'Y'            \
)

#define IS_NULL_STR(p) ( \
  p[0] == 'N' &&         \
  p[1] == 'U' &&         \
  p[2] == 'L' &&         \
  p[3] == 'L'            \
)

#define IS__binary(p) ( \
  p[0] == '_' &&        \
  p[1] == 'b' &&        \
  p[2] == 'i' &&        \
  p[3] == 'n' &&        \
  p[4] == 'a' &&        \
  p[5] == 'r' &&        \
  p[6] == 'y'           \
)

#define IS_MAYBE_KEY(p) (IS_KEY(p) || IS_INDEX(p) || IS_UNIQUE(p) || IS_PRIMARY(p))

#define IS_WSPACE(p) (*p == ' ' || *p == '\t')
#define SKIP_WSPACE(p) { \
  while (*p != '\0' && IS_WSPACE(p)) p++;     \
}
#define SKIP_UNTIL_WSPACE(p) { \
  while (*p != '\0' && !IS_WSPACE(p)) p++;          \
}

