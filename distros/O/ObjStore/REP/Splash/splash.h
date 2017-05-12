#ifndef __splash_h__
#define __splash_h__

/*
 * Version 1.91
 * Written by Jim Morris,  morris@netcom.com
 * Kudos to Larry Wall for inventing Perl
 * Copyrights only exist on the regex stuff, and all have been left intact.
 * The only thing I ask is that you let me know of any nifty fixes or
 * additions.
 * 
 * Credits:
 * I'd like to thank Michael Golan <mg@Princeton.EDU> for his critiques
 * and clever suggestions. Some of which have actually been implemented
 *
 * 19970619 JPRIT: hacked for use with ObjectStore
 */

#define	INLINE	inline

// ************************************************************
// This is the base class for SPList, it handles the underlying
// dynamic array mechanism
// ************************************************************

template<class T>
class SPListBase : public os_virtual_behavior
{
private:
    T *a;
    int cnt;
    int first;
    int allocinc; //unused
    int firstshift;
    void grow(int amnt= 0, int newcnt= -1);

protected:
    int allocated;

public:
#ifdef	USLCOMPILER
    // USL 3.0 bug with enums losing the value
    SPListBase(int n, int fs = 1)
#else
    SPListBase(int n, int fs = 1)
#endif
    {
      os_segment *WHERE = os_segment::of(this);
      assert(n > 0);
        NEW_OS_ARRAY(a, WHERE, T::get_os_typespec(), T, n);
//	a= new(WHERE, T::get_os_typespec(), n) T[n];
	cnt= 0;
	firstshift = fs;
        first= n>>firstshift;
	allocated= n;
	allocinc= 0; //unused
	DEBUG_splash(warn("SPListBase a= %p, first= %d\n", a, first));
    }

//    SPListBase(const SPListBase<T>& n);
//    SPListBase<T>& SPListBase<T>::operator=(const SPListBase<T>& n);
    virtual ~SPListBase(){
      DEBUG_splash(warn("~SPListBase() a= %p\n", a));
      delete [] a;
    }

    INLINE T& operator[](const int i);
    INLINE const T& operator[](const int i) const;

    int count(void) const{ return cnt; }

    void compact(const int i);
    void add(const T& n);
    void insert(int at, int slots);
    void erase(void){
      for (int xx=0; xx < cnt; xx++) a[xx+first].set_undef();
      cnt= 0; first= (allocated>>firstshift);
    }
};

// ************************************************************
// SPList
// ************************************************************

template <class T>
class SPList: public SPListBase<T>
{
public:
    SPList(int sz= 10, int fs=1): SPListBase<T>(sz, fs){}
    
    // stuff I want public to see from SPListBase
    T& operator[](const int i){return SPListBase<T>::operator[](i);}
    const T& operator[](const int i) const{return SPListBase<T>::operator[](i);}
    SPListBase<T>::count;   // some compilers don''t like this

    // add perl-like synonyms
    void reset(void){ erase(); }
    int scalar(void) const { return count(); }
    int size_allocated(void) const { return allocated; }

    operator void*() { return count()?this:0; } // so it can be used in tests
    int isempty(void) const{ return !count(); } // for those that don''t like the above (hi michael)
};

// ************************************************************
// Implementation of template functions for splistbase
// ************************************************************

template <class T>
INLINE T& SPListBase<T>::operator[](const int i)
{
    assert((i >= 0) && (first >= 0) && ((first+cnt) <= allocated));
    int indx= first+i;
        
    if(indx >= allocated){  // need to grow it
	grow((indx-allocated)+3, i+1); // index as yet unused element
	indx= first+i;			  // first will have changed in grow()
    }
    if (!(indx >= 0 && indx < allocated)) {
	croak("Can't access [%d/%d]; first=%d",
	      indx, allocated, first);
    }

    if(i >= cnt) cnt= i+1;  // it grew
    return a[indx];
}

template <class T>
INLINE const T& SPListBase<T>::operator[](const int i) const
{
     assert((i >= 0) && (i < cnt));
     return a[first+i];
}


/* 
** increase size of array, default means array only needs
** to grow by at least 1 either at the end or start
** First tries to re-center the first pointer
** Then will increment the array by the inc amount
*/
template <class T>
void SPListBase<T>::grow(int amnt, int newcnt){
  int mingrow;
  int newfirst;
    
    if(amnt <= 0){ // only needs to grow by 1
      
      if (cnt+1 < allocated) {
	memmove(a, &a[first], sizeof(T)*cnt);
	for (int xx=cnt; xx < cnt + first; xx++) {
	  a[xx].FORCEUNDEF();
	}
	first = 0;
	return;
      }

      /* XXX
        newfirst= (allocated>>firstshift) - (cnt>>firstshift); // recenter first
        if(newfirst > 0 && (newfirst+cnt+1) < allocated){ // this is all we need to do
            for(int i=0;i<cnt;i++){ // move rest up or down
                int idx= (first > newfirst) ? i : cnt-1-i;
                a[newfirst+idx]= a[first+idx];
	    }
	DEBUG_splash(warn("SPListBase::grow() moved a= %p, first= %d, newfirst= %d, amnt= %d, cnt= %d, allocated= %d\n",
			  a, first, newfirst, amnt, cnt, allocated));
           first= newfirst;
           return;
        }
      */
    }

    
    if (allocated < 20) mingrow = 2;
    else mingrow = allocated * .1;
    if(amnt <= mingrow) amnt= mingrow;

    if(newcnt < 0) newcnt= cnt;   // default
    allocated += amnt;
    os_segment *WHERE = os_segment::of(a);
    T *tmp;
    NEW_OS_ARRAY(tmp, WHERE, T::get_os_typespec(), T, allocated);
//    tmp = new(WHERE, T::get_os_typespec(),allocated) T[allocated];
    newfirst= (allocated>>firstshift) - (newcnt>>firstshift);
    DEBUG_splash(warn("SPListBase(0x%x)->grow(): old= %p, a= %p, newfirst= %d, amnt= %d, cnt= %d, allocated= %d\n",
		      this, a, tmp, newfirst, amnt, cnt, allocated));
    memcpy(tmp+newfirst, a+first, cnt*sizeof(T));
    for(int i=0;i<cnt;i++) a[first+i].FORCEUNDEF();
    DEBUG_splash(warn("SPListBase(0x%x)->grow(): done copying\n", this));
    delete [] a;  //prefer not to call destructors...
    a= tmp;
    first= newfirst;
}

template <class T>
void SPListBase<T>::add(const T& n){
    if(cnt+first >= allocated) grow();
    assert((cnt+first) < allocated);
    a[first+cnt]= n;
    DEBUG_splash(warn("add(const T& n): first= %d, cnt= %d, idx= %d, allocated= %d\n",
                first, cnt, first+cnt, allocated));
    cnt++;
}

template <class T>
void SPListBase<T>::insert(int ip, int slots)
{
    assert(ip >= 0 && ip <= cnt);
    if((first+cnt+slots) >= allocated) grow(slots+1);
    if (cnt-ip > 0) {
      memmove(&a[first+ip+slots], &a[first+ip], sizeof(T)*(cnt-ip));
      for (int xx=0; xx < slots; xx++) {
	a[first+ip+xx].FORCEUNDEF();
      }
    }
    cnt += slots;

    DEBUG_splash(warn("insert(ip=%d, slots=%d): first= %d, cnt= %d, idx= %d, allocated= %d\n", ip, slots,
		      first, cnt, first+ip, allocated));
}

template <class T>
void SPListBase<T>::compact(const int n){ // shuffle down starting at n
int i;
    assert((n >= 0) && (n < cnt));
    a[first+n].set_undef();
    if(n == 0) {
      first++;
    } else {
      if (cnt-1-n > 0) {
	memmove(&a[first+n], &a[first+n+1], sizeof(T)*(cnt-1-n));
      }
      //for(i=n;i<cnt-1;i++) {
	//a[first+i]= a[(first+i)+1];
      //}
      a[cnt-1+first].FORCEUNDEF();  //snark the last element
    }
    cnt--;
}


#endif
