#ifndef BITVECT_H
#define BITVECT_H 1

/* === Bit vectors ========================================================= */

/* ... Generic macros ...................................................... */

#define INLINE_DECLARE(P) STATIC P
#define INLINE_DEFINE

#ifndef BV_UNIT
# define BV_UNIT unsigned char
#endif

#define BITS(T) (CHAR_BIT * sizeof(T))

#define BV_SIZE(I) (((((I) % BITS(BV_UNIT)) != 0) + ((I) / BITS(BV_UNIT))) * sizeof(BV_UNIT))

/* 0 <= I <  CHAR_BIT * sizeof(T) */
#define BV_MASK_LOWER(T, I)  (~((~((T) 0)) << (I)))
/* 0 <  I <= CHAR_BIT * sizeof(T) */
#define BV_MASK_HIGHER(T, I) ((~((T) 0)) << (BITS(T) - (I)))

#define BV_DO_ALIGNED_FORWARD(T, A)       \
 mask = BV_MASK_HIGHER(T, BITS(T) - fs);  \
 if (fs + l <= BITS(T)) {                 \
  /* Branching is apparently useless,     \
   * but since we can't portably shift    \
   * CHAR_BITS from a char...             \
   * Actually, we only copy up to this */ \
  if (fs + l < BITS(T))                   \
   mask &= BV_MASK_LOWER(T, fs + l);      \
  *t = (*t & ~mask) | (*f & mask);        \
 } else {                                 \
  size_t lo, lk;                          \
  *t = (*t & ~mask) | (*f & mask);        \
  ++t;                                    \
  ++f;                                    \
  l -= (BITS(T) - ts);                    \
  lo = l % BITS(T);                       \
  lk = l / BITS(T);                       \
  BV_##A##_UNIT_ALIGNED(T, t, f, lk);     \
  t += lk;                                \
  f += lk;                                \
  if (lo) {                               \
   mask = BV_MASK_LOWER(T, lo);           \
   *t = (*t & ~mask) | (*f & mask);       \
  }                                       \
 }

#define BV_DO_ALIGNED_BACKWARD(T, A)         \
 if (fs + l <= BITS(T)) {                    \
  mask = BV_MASK_HIGHER(T, BITS(T) - fs);    \
  /* Branching is apparently useless,        \
   * but since we can't portably shift       \
   * CHAR_BITS from a char...                \
   * Actually, we only copy up to this */    \
  if (fs + l < BITS(T))                      \
   mask &= BV_MASK_LOWER(T, fs + l);         \
  *t = (*t & ~mask) | (*f & mask);           \
 } else {                                    \
  size_t lo, lk;                             \
  l -= (BITS(T) - ts);                       \
  lo = l % BITS(T);                          \
  lk = l / BITS(T);                          \
  ++t;                                       \
  ++f;                                       \
  if (lo) {                                  \
   mask = BV_MASK_LOWER(T, lo);              \
   t[lk] = (t[lk] & ~mask) | (f[lk] & mask); \
  }                                          \
  BV_##A##_UNIT_ALIGNED(T, t, f, lk);        \
  mask = BV_MASK_HIGHER(T, BITS(T) - fs);    \
  t[-1] = (t[-1] & ~mask) | (f[-1] & mask);  \
 }

#define BV_DO_LEFT_FORWARD(T, A)                        \
 step = ts - fs;                                        \
 mask = BV_MASK_HIGHER(T, BITS(T) - ts);                \
 if (ts + l <= BITS(T)) {                               \
  if (ts + l < BITS(T))                                 \
   mask &= BV_MASK_LOWER(T, ts + l);                    \
  *t = (*t & ~mask) | ((*f & (mask >> step)) << step);  \
 } else {                                               \
  size_t pets = BITS(T) - step;                         \
  l -= (BITS(T) - ts);                                  \
  *t = (*t & ~mask) | ((*f & (mask >> step)) << step);  \
  ++t;                                                  \
  if (l <= step) {                                      \
   mask = BV_MASK_LOWER(T, l);                          \
   *t = (*t & ~mask) | ((*f & (mask << pets)) >> pets); \
  } else {                                              \
   ins = (*f & BV_MASK_HIGHER(T, step)) >> pets;        \
   ++f;                                                 \
   offset = l % BITS(T);                                \
   end    = t + l / BITS(T);                            \
   while (t < end) {                                    \
    BV_##A##_UNIT_LEFT_FORWARD(T, t, f, step);          \
    ++t; ++f;                                           \
   }                                                    \
   if (offset > step) {                                 \
    mask = BV_MASK_LOWER(T, offset - step);             \
    *t = (*t & (~mask << step))                         \
       | ((*f & mask) << step)                          \
       | ins;                                           \
   } else if (offset) {                                 \
    mask = BV_MASK_LOWER(T, offset);                    \
    *t = (*t & ~mask) | (ins & mask);                   \
   }                                                    \
  }                                                     \
 }

#define BV_DO_RIGHT_FORWARD(T, A)                            \
 step = fs - ts;                                             \
 mask = BV_MASK_HIGHER(T, BITS(T) - fs);                     \
 if (fs + l <= BITS(T)) {                                    \
  if (fs + l < BITS(T))                                      \
   mask &= BV_MASK_LOWER(T, fs + l);                         \
  *t = (*t & ~(mask >> step)) | ((*f & mask) >> step);       \
 } else {                                                    \
  l  -= (BITS(T) - fs);                                      \
  ins = ((*f & mask) >> step) | (*t & BV_MASK_LOWER(T, ts)); \
  ++f;                                                       \
  offset = l % BITS(T);                                      \
  end    = f + l / BITS(T) + (offset > step);                \
  while (f < end) {                                          \
   BV_##A##_UNIT_RIGHT_FORWARD(T, t, f, step);               \
   ++t; ++f;                                                 \
  }                                                          \
  if (!offset)                                               \
   offset += BITS(T);                                        \
  if (offset > step) {                                       \
   mask = BV_MASK_LOWER(T, offset - step);                   \
   *t = (*t & ~mask) | (ins & mask);                         \
  } else {                                                   \
   mask = BV_MASK_LOWER(T, offset);                          \
   *t = (*t & (~mask << (BITS(T) - step)))                   \
      | ((*f & mask) << (BITS(T) - step))                    \
      | ins;                                                 \
  }                                                          \
 }

#define BV_DO_LEFT_BACKWARD(T, A)                       \
 step = ts - fs;                                        \
 mask = BV_MASK_LOWER(T, BITS(T) - ts);                 \
 if (ts + l <= BITS(T)) {                               \
  if (ts + l < BITS(T))                                 \
   mask &= BV_MASK_HIGHER(T, ts + l);                   \
  *t = (*t & ~mask) | ((*f & (mask << step)) >> step);  \
 } else {                                               \
  size_t pets = BITS(T) - step;                         \
  l -= (BITS(T) - ts);                                  \
  *t = (*t & ~mask) | ((*f & (mask << step)) >> step);  \
  --t;                                                  \
  if (l <= step) {                                      \
   mask = BV_MASK_HIGHER(T, l);                         \
   *t = (*t & ~mask) | ((*f & (mask >> pets)) << pets); \
  } else {                                              \
   ins = (*f & BV_MASK_LOWER(T, step)) << pets;         \
   --f;                                                 \
   offset = l % BITS(T);                                \
   begin  = t - l / BITS(T);                            \
   while (t > begin) {                                  \
    BV_##A##_UNIT_LEFT_BACKWARD(T, t, f, step);         \
    --t; --f;                                           \
   }                                                    \
   if (offset > step) {                                 \
    mask = BV_MASK_HIGHER(T, offset - step);            \
    *t = (*t & (~mask >> step))                         \
       | ((*f & mask) >> step)                          \
       | ins;                                           \
   } else if (offset) {                                 \
    mask = BV_MASK_HIGHER(T, offset);                   \
    *t = (*t & ~mask) | (ins & mask);                   \
   }                                                    \
  }                                                     \
 }

#define BV_DO_RIGHT_BACKWARD(T, A)                            \
 step = fs - ts;                                              \
 mask = BV_MASK_LOWER(T, BITS(T) - fs);                       \
 if (fs + l <= BITS(T)) {                                     \
  if (fs + l < BITS(T))                                       \
   mask &= BV_MASK_HIGHER(T, fs + l);                         \
  *t = (*t & ~(mask << step)) | ((*f & mask) << step);        \
 } else {                                                     \
  l  -= (BITS(T) - fs);                                       \
  ins = ((*f & mask) << step);                                \
  if (ts)                                                     \
   ins |= (*t & BV_MASK_HIGHER(T, ts));                       \
  --f;                                                        \
  offset = l % BITS(T);                                       \
  begin  = f - l / BITS(T) + (offset <= step);                \
  while (f >= begin) {                                        \
   BV_##A##_UNIT_RIGHT_BACKWARD(T, t, f, step);               \
   --t; --f;                                                  \
  }                                                           \
  if (!offset)                                                \
   offset += BITS(T);                                         \
  if (offset > step) {                                        \
   mask = BV_MASK_HIGHER(T, offset - step);                   \
   *t = (*t & ~mask) | (ins & mask);                          \
  } else {                                                    \
   mask = BV_MASK_HIGHER(T, offset);                          \
   *t = (*t & (~mask >> (BITS(T) - step)))                    \
      | ((*f & mask) >> (BITS(T) - step))                     \
      | ins;                                                  \
  }                                                           \
 }

/* ... Copy ................................................................. */

#define BV_COPY_UNIT_ALIGNED(X, T, F, L) memcpy((T), (F), (L) * sizeof(X))

/* Save the O - B higher bits, shift B bits left, add B bits from f at right */
#define BV_COPY_UNIT_LEFT_FORWARD(X, T, F, B) \
 *(T) = (*(F) << (B)) | ins;                  \
 ins  = *(F) >> (BITS(X) - (B));

/* Save the B lower bits, shift B bits right, add B bits from F at left */
#define BV_COPY_UNIT_RIGHT_FORWARD(X, T, F, B) \
 *(T) = (*(F) << (BITS(X) - (B))) | ins;       \
 ins  = *(F) >> (B);

#define T BV_UNIT
INLINE_DECLARE(void bv_copy(void *t_, size_t ts, const void *f_, size_t fs, size_t l))
#ifdef INLINE_DEFINE
{
 size_t offset, step;
 T ins, mask, *t = (T *) t_;
 const T *f = (const T *) f_, *end;

 t  += ts / BITS(T);
 ts %= BITS(T);

 f  += fs / BITS(T);
 fs %= BITS(T);

 if (ts == fs) {
  BV_DO_ALIGNED_FORWARD(T, COPY);
 } else if (ts < fs) {
  BV_DO_RIGHT_FORWARD(T, COPY);
 } else { /* ts > fs */
  BV_DO_LEFT_FORWARD(T, COPY);
 }

 return;
}
#endif /* INLINE_DEFINE */
#undef T

/* ... Move ................................................................ */

#define BV_MOVE_UNIT_ALIGNED(X, T, F, L) memmove((T), (F), (L) * sizeof(X))

#define BV_MOVE_UNIT_LEFT_FORWARD(X, T, F, B) \
 tmp  = *(F) >> (BITS(X) - (B));              \
 *(T) = (*(F) << (B)) | ins;                  \
 ins  = tmp;

#define BV_MOVE_UNIT_RIGHT_FORWARD(X, T, F, B) \
 tmp  = *(F) >> (B);                           \
 *(T) = (*(F) << (BITS(X) - (B))) | ins;       \
 ins  = tmp;

#define BV_MOVE_UNIT_LEFT_BACKWARD(X, T, F, B) \
 tmp  = *(F) << (BITS(X) - (B));               \
 *(T) = (*(F) >> (B)) | ins;                   \
 ins  = tmp;

#define BV_MOVE_UNIT_RIGHT_BACKWARD(X, T, F, B) \
 tmp  = *(F) << (B);                            \
 *(T) = (*(F) >> (BITS(X) - (B))) | ins;        \
 ins  = tmp;

#define BV_MOVE_INIT_REVERSE(T, V, VS) \
 z     = (VS) + l;                     \
 (VS)  = z % BITS(T);                  \
 if ((VS) > 0) {                       \
  (V)  = bv + (z / BITS(T));           \
  (VS) = BITS(T) - (VS);               \
 } else {                              \
  /* z >= BITS(T) because l > 0 */     \
  (V)  = bv + (z / BITS(T)) - 1;       \
 }

#define T BV_UNIT
INLINE_DECLARE(void bv_move(void *bv_, size_t ts, size_t fs, size_t l))
#ifdef INLINE_DEFINE
{
 size_t to, fo, offset, step;
 T ins, tmp, mask, *bv = (T *) bv_, *t, *f;
 const T *begin, *end;

 if (ts == fs)
  return;

 to = ts % BITS(T);
 fo = fs % BITS(T);

 if (ts < fs) {
  t  = bv + ts / BITS(T);
  ts = to;
  f  = bv + fs / BITS(T);
  fs = fo;
  if (ts == fs) {
   BV_DO_ALIGNED_FORWARD(T, MOVE);
  } else if (ts < fs) {
   BV_DO_RIGHT_FORWARD(T, MOVE);
  } else { /* ts > fs */
   BV_DO_LEFT_FORWARD(T, MOVE);
  }
 } else if (to == fo) {
  t  = bv + ts / BITS(T);
  ts = to;
  f  = bv + fs / BITS(T);
  fs = fo;
  BV_DO_ALIGNED_BACKWARD(T, MOVE);
 } else { /* ts > fs */
  size_t z;
  BV_MOVE_INIT_REVERSE(T, t, ts);
  BV_MOVE_INIT_REVERSE(T, f, fs);
  if (ts < fs) {
   BV_DO_RIGHT_BACKWARD(T, MOVE);
  } else { /* ts > fs */
   BV_DO_LEFT_BACKWARD(T, MOVE);
  }
 }

 return;
}
#endif /* INLINE_DEFINE */
#undef T

/* ... Test if zero ........................................................ */

#define T BV_UNIT
INLINE_DECLARE(int bv_zero(const void *bv_, size_t s, size_t l))
#ifdef INLINE_DEFINE
{
 size_t o;
 T mask;
 const T *bv = (const T *) bv_, *end;

 bv += s / BITS(T);
 o   = s % BITS(T);

 mask = BV_MASK_HIGHER(T, BITS(T) - o);
 if (o + l <= BITS(T)) {
  if (o + l < BITS(T))
   mask &= BV_MASK_LOWER(T, o + l);
  if (*bv & mask)
   return 0;
 } else {
  if (*bv & mask)
   return 0;
  ++bv;
  l  -= (BITS(T) - o);
  end = bv + l / BITS(T);
  for (; bv < end; ++bv) {
   if (*bv)
    return 0;
  }
  o = l % BITS(T);
  if (o) {
   mask = BV_MASK_LOWER(T, o);
   if (*bv & mask)
    return 0;
  }
 }

 return 1;
}
#endif /* INLINE_DEFINE */
#undef T

/* ... Compare ............................................................. */

#define BV_EQ(T, B1, B2) \
 if (((T) (B1)) != ((T) (B2))) return 0;

#define BV_EQ_MASK(T, B1, B2, M) BV_EQ(T, (B1) & (M), (B2) & (M))

#define BV_EQ_LEFT(T, B1, B2, L, B)        \
 offset = (L) % BITS(T);                   \
 end    = (B1) + (L) / BITS(T);            \
 while ((B1) < end) {                      \
  BV_EQ(T, *(B1), (*(B2) << (B)) | ins);   \
  ins = *(B2) >> (BITS(T) - (B));          \
  ++(B1); ++(B2);                          \
 }                                         \
 if (offset > (B)) {                       \
  mask = BV_MASK_LOWER(T, offset - (B));   \
  BV_EQ(T, *(B1) & ~(~mask << (B)),        \
           ((*(B2) & mask) << (B)) | ins); \
 } else if (offset) {                      \
  mask = BV_MASK_LOWER(T, offset);         \
  BV_EQ_MASK(T, *(B1), ins, mask);         \
 }

#define BV_EQ_RIGHT(T, B1, B2, L, B)                   \
 offset = (L) % BITS(T);                               \
 end    = (B2) + (L) / BITS(T) + (offset >= (B));      \
 while ((B2) < end) {                                  \
  BV_EQ(T, *(B1), (*(B2) << (BITS(T) - (B))) | ins);   \
  ins = *(B2) >> (B);                                  \
  ++(B1); ++(B2);                                      \
 }                                                     \
 if (!offset)                                          \
  offset += BITS(T);                                   \
 if (offset >= (B)) {                                  \
  mask = BV_MASK_LOWER(T, offset - (B));               \
  BV_EQ_MASK(T, *(B1), ins, mask);                     \
 } else {                                              \
  mask = BV_MASK_LOWER(T, offset);                     \
  BV_EQ(T, *(B1) & ~(~mask << (BITS(T) - (B))),        \
           ((*(B2) & mask) << (BITS(T) - (B))) | ins); \
 }

#define T BV_UNIT
INLINE_DECLARE(int bv_eq(const void *bv1_, size_t s1, const void *bv2_, size_t s2, size_t l))
#ifdef INLINE_DEFINE
{
 size_t offset, step;
 T ins, mask;
 const T *bv1 = (const T *) bv1_, *bv2 = (const T *) bv2_, *end;

 bv1 += s1 / BITS(T);
 s1  %= BITS(T);

 bv2 += s2 / BITS(T);
 s2  %= BITS(T);

 if (s1 == s2) {

  mask = BV_MASK_HIGHER(T, BITS(T) - s2);
  if (s2 + l <= BITS(T)) {
   if (s2 + l < BITS(T)) {
    mask &= BV_MASK_LOWER(T, s2 + l);
   }
   BV_EQ_MASK(T, *bv1, *bv2, mask);
  } else {
   int ret;
   size_t lo, lk;
   BV_EQ_MASK(T, *bv1, *bv2, mask);
   ++bv1;
   ++bv2;
   l -= (BITS(T) - s2);
   lo = l % BITS(T);
   lk = l / BITS(T);
   if ((ret = memcmp(bv1, bv2, lk * sizeof(T))) != 0)
    return 0;
   if (lo) {
    mask = BV_MASK_LOWER(T, lo);
    BV_EQ_MASK(T, *bv1, *bv2, mask);
   }
  }

 } else if (s1 < s2) {

  step = s2 - s1;
  mask = BV_MASK_HIGHER(T, BITS(T) - s2);
  if (s2 + l <= BITS(T)) {
   if (s2 + l < BITS(T))
    mask &= BV_MASK_LOWER(T, s2 + l);
   BV_EQ(T, *bv1 & (mask >> step), (*bv2 & mask) >> step);
  } else {
   l -= (BITS(T) - s2);
   ins = ((*bv2 & mask) >> step) | (*bv1 & BV_MASK_LOWER(T, s1));
   ++bv2;
   offset = l % BITS(T);
   end    = bv2 + l / BITS(T) + (offset >= step);
   while (bv2 < end) {
    BV_EQ(T, *bv1, (*bv2 << (BITS(T) - step)) | ins);
    ins = *bv2 >> step;
    ++bv1; ++bv2;
   }
   if (!offset)
    offset += BITS(T);
   if (offset >= step) {
    mask = BV_MASK_LOWER(T, offset - step);
    BV_EQ_MASK(T, *bv1, ins, mask);
   } else {
    mask = BV_MASK_LOWER(T, offset);
    BV_EQ(T, *bv1 & ~(~mask << (BITS(T) - step)),
             ((*bv2 & mask) << (BITS(T) - step)) | ins);
   }
/*   BV_EQ_RIGHT(T, bv1, bv2, l, step); */
  }

 } else { /* s1 > s2 */

  step = s1 - s2;
  mask = BV_MASK_HIGHER(T, BITS(T) - s1);
  if (s1 + l <= BITS(T)) {
   if (s1 + l < BITS(T))
    mask &= BV_MASK_LOWER(T, s1 + l);
   BV_EQ(T, *bv1 & mask, (*bv2 & (mask >> step)) << step);
  } else {
   size_t pets = BITS(T) - step;
   l -= (BITS(T) - s1);
   BV_EQ(T, *bv1 & mask, (*bv2 & (mask >> step)) << step);
   ++bv1;
   if (l <= step) {
    mask = BV_MASK_LOWER(T, l);
    BV_EQ(T, *bv1 & mask, (*bv2 & (mask << pets)) >> pets);
   } else {
    ins = (*bv2 & BV_MASK_HIGHER(T, step)) >> pets;
    ++bv2;
    offset = l % BITS(T);
    end    = bv1 + l / BITS(T);
    while (bv1 < end) {
     BV_EQ(T, *bv1, (*bv2 << step) | ins);
     ins = *bv2 >> (BITS(T) - step);
     ++bv1; ++bv2;
    }
    if (offset > step) {
     mask = BV_MASK_LOWER(T, offset - step);
     BV_EQ(T, *bv1 & ~(~mask << step),
              ((*bv2 & mask) << step) | ins);
    } else if (offset) {
     mask = BV_MASK_LOWER(T, offset);
     BV_EQ_MASK(T, *bv1, ins, mask);
    }
/*    BV_EQ_LEFT(T, bv1, bv2, l, step); */
   }
  }

 }

 return 1;
}
#endif /* INLINE_DEFINE */
#undef T

/* ... Fill ................................................................ */

#define T unsigned char
INLINE_DECLARE(void bv_fill(void *bv_, size_t s, size_t l, unsigned int f))
#ifdef INLINE_DEFINE
{
 size_t o, k;
 T mask, *bv = (T *) bv_;

 if (f)
  f = ~0u;

 bv += s / BITS(T);
 o   = s % BITS(T);

 mask = BV_MASK_HIGHER(T, BITS(T) - o);
 if (o + l <= BITS(T)) {
  if (o + l < BITS(T))
   mask &= BV_MASK_LOWER(T, o + l);
  *bv = (*bv & ~mask) | (f & mask);
 } else {
  *bv = (*bv & ~mask) | (f & mask);
  ++bv;
  l -= (BITS(T) - o);
  k = l / BITS(T);
  o = l % BITS(T);
  memset(bv, f, k);
  if (o) {
   mask = BV_MASK_LOWER(T, o);
   bv += k;
   *bv = (*bv & ~mask) | (f & mask);
  }
 }

 return;
}
#endif /* INLINE_DEFINE */
#undef T

/* ========================================================================= */

#endif /* BITVECT_H */
