
#ifndef VECTOR_H
#define VECTOR_H

// namespace collisions
#undef write
#undef read
#undef pause
#undef setbuf

#include <math.h>
#include <stdlib.h>
#include <algorithm>
#include <iostream>

template<typename T,int DIM>
class Vector {

    public:
        T arr[DIM];

        static int size () { return DIM; }

              T& operator[] (int i)       { return arr[i]; }
        const T& operator[] (int i) const { return arr[i]; }

        Vector<T,DIM>& operator= (const Vector<T,DIM>& rhs) {
            std::copy(rhs.arr,rhs.arr + DIM, arr);
            return *this;
        }

};

template<typename T,int DIM>
bool operator== (const Vector<T,DIM>& lhs, const Vector<T,DIM>& rhs)
    { return std::equal(lhs.arr, lhs.arr + DIM, rhs.arr); }

template<typename T,int DIM>
bool operator!= (const Vector<T,DIM>& lhs, const Vector<T,DIM>& rhs) {
    for (unsigned i=0; i<DIM; ++i) { if (lhs[i] != rhs[i]) return true; }
    return false;
}

template<typename T,int DIM>
Vector<T,DIM> operator+ (const Vector<T,DIM>& lhs, const Vector<T,DIM>& rhs) {
    Vector<T,DIM> res;
    for (unsigned i=0; i<DIM; ++i) { res[i] = lhs[i] + rhs[i]; }
    return res;
}

template<typename T,int DIM>
Vector<T,DIM> operator- (const Vector<T,DIM>& lhs, const Vector<T,DIM>& rhs) {
    Vector<T,DIM> res;
    for (unsigned i=0; i<DIM; ++i) { res[i] = lhs[i] - rhs[i]; }
    return res;
}

template<int DIM>
Vector<float,DIM> operator- (const Vector<int,DIM>& lhs, const Vector<float,DIM>& rhs) {
    Vector<float,DIM> res;
    for (unsigned i=0; i<DIM; ++i) { res[i] = ((float) lhs[i]) - rhs[i]; }
    return res;
}

// * on int vector and float k to int vector
template<int DIM>
Vector<int,DIM> operator* (const Vector<int,DIM>& t, float k) {
    Vector<int,DIM> res;
    for (unsigned i=0; i<DIM; ++i) { res[i] = (int) round(k * (float) t[i]); }
    return res;
}

// * on float vector and float k to float vector
template<int DIM>
Vector<float,DIM> operator* (const Vector<float,DIM>& t, float k) {
    Vector<float,DIM> res;
    for (unsigned i=0; i<DIM; ++i) { res[i] = k * t[i]; }
    return res;
}

// * on float vector and int k to int vector
template<int DIM>
Vector<int,DIM> operator* (const Vector<float,DIM>& t, int k) {
    Vector<int,DIM> res;
    for (unsigned i=0; i<DIM; ++i) { res[i] = (int) round(t[i] * (float) k); }
    return res;
}

template<typename T,int DIM>
Vector<T,DIM> operator/ (const Vector<T,DIM>& t, float k) {
    Vector<T,DIM> res;
    for (unsigned i=0; i<DIM; ++i) { res[i] = t[i] / k; }
    return res;
}

template<typename T,int DIM>
std::ostream& operator<< (std::ostream& os, const Vector<T,DIM>& t)
{
    os << "{" << t[0];
    for (unsigned i=1; i<DIM; ++i) { os << "," << t[i]; }
    os << "}";
    return os;
}

template<typename T,int DIM>
float distance(const Vector<T,DIM>& lhs, const Vector<T,DIM>& rhs) {
    Vector<T,DIM> diff = lhs - rhs;
    float d = 0;
    for (unsigned i=0; i<DIM; ++i) d += diff[i] * diff[i];
    return sqrt(d);
}

template<int DIM>
float distance(const Vector<int,DIM>& lhs, const Vector<float,DIM>& rhs) {
    Vector<float,DIM> diff = lhs - rhs;
    float d = 0;
    for (unsigned i=0; i<DIM; ++i) d += diff[i] * diff[i];
    return sqrt(d);
}

template<typename T, int DIM>
Vector<T,DIM> mult_floor(const Vector<T,DIM>& t, float k) {
    Vector<T,DIM> res;
    for (unsigned i=0; i<DIM; ++i) { res[i] = (int) (k * (float) t[i]); }
    return res;
}

template<int DIM>
Vector<int,DIM> round_vec(const Vector<float,DIM>& t) {
    Vector<int,DIM> res;
    for (unsigned i=0; i<DIM; ++i) { res[i] = (int) round(t[i]); }
    return res;
}

#endif
