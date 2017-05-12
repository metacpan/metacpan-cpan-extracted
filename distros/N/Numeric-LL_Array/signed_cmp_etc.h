#define my_lt(a,b)	((a) <  (b))
#define my_le(a,b)	((a) <= (b))
#define my_eq(a,b)	((a) == (b))
#define my_ne(a,b)	((a) != (b))

/* signed vs unsigned; avoid bubbles */
#define my_lt_su(a,b)	(((a) <  0) | ((a) <  (b)))
#define my_le_su(a,b)	(((a) <  0) | ((a) <= (b)))
#define my_eq_su(a,b)	(((a) >= 0) & ((a) == (b)))
#define my_ne_su(a,b)	(((a) <  0) | ((a) != (b)))

/* unsigned vs signed; avoid bubbles */
#define my_lt_us(a,b)	(((b) >= 0) & ((a) <  (b)))
#define my_le_us(a,b)	(((b) >= 0) & ((a) <= (b)))
#define my_eq_us(a,b)	(((b) >= 0) & ((a) == (b)))
#define my_ne_us(a,b)	(((b) <  0) | ((a) != (b)))

#define ldexp_neg(a,b)	ldexp((a), -(b))
#define ldexp_negl(a,b)	ldexpl((a), -(b))

#define my_ne0(a)	(0 != (a))

		/* how is one of: EMPTY, _su, _us.  1s are to equalize return type */
#define assign_min_how(how,a,b,c)	(my_le ## how((a),(b)) ? (void)((c) = (a)) : (void)((c) = (b)))
#define assign_max_how(how,a,b,c)	(my_le ## how((a),(b)) ? (void)((c) = (b)) : (void)((c) = (a)))

#define assign_min(a,b,c)	assign_min_how(,(a),(b),(c))
#define assign_max(a,b,c)	assign_max_how(,(a),(b),(c))

#define assign_min_su(a,b,c)	assign_min_how(_su,(a),(b),(c))
#define assign_max_su(a,b,c)	assign_max_how(_su,(a),(b),(c))
#define assign_min_us(a,b,c)	assign_min_how(_us,(a),(b),(c))
#define assign_max_us(a,b,c)	assign_max_how(_us,(a),(b),(c))

	/* As above, with &c == &a */
#define self_assign_min_how(how,a,b)	(my_le ## how((a),(b)) ? (void)0 : (void)((a) = (b)))
#define self_assign_max_how(how,a,b)	(my_lt ## how((a),(b)) ? (void)((a) = (b)) : (void)0)

#define self_assign_min(a,b)	self_assign_min_how(,(a),(b))
#define self_assign_max(a,b)	self_assign_max_how(,(a),(b))

#define self_assign_min_su(a,b)	self_assign_min_how(_su,(a),(b))
#define self_assign_max_su(a,b)	self_assign_max_how(_su,(a),(b))
#define self_assign_min_us(a,b)	self_assign_min_how(_us,(a),(b))
#define self_assign_max_us(a,b)	self_assign_max_how(_us,(a),(b))

#define	powl_cbrtl(a)	((a)>=0 ? powl((a),1/(long double)3) : -powl(-(a),1/(long double)3))

#ifdef MY_NEED_UQUAD_TO_DOUBLE
double uquad2double(Uquad_t u);
#  define have_uquad2double()	0
#else
#  define uquad2double(arg)	(arg)
#  define have_uquad2double()	1
#endif

#define my_strfy(a)	#a
#define my_strfy2a(a,b)	my_strfy(a##__##b)
#define methmakenam1(f,n)	my_strfy2a(f,n)
#define methmakename(f)	methmakenam1(f,THIS_OP_NAME)
