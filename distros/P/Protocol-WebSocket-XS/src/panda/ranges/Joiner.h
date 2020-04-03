#pragma once
#include <iterator>

namespace panda { namespace ranges {

    template <typename RoRIterator>
    struct JoinerIterator {

        using Container       = typename std::iterator_traits<RoRIterator>::value_type;
        using ElementIterator = typename Container::const_iterator;

        RoRIterator     container_begin;
        RoRIterator     container_end;
        RoRIterator     container;
        ElementIterator element;

        JoinerIterator (const RoRIterator& begin, const RoRIterator& end) : container_begin(begin), container_end(end), container(begin) {
            if (container != container_end) {
                element = std::begin(*container);
                find_new_begin();
            }
        }

        const typename std::iterator_traits<ElementIterator>::reference operator*  () const { return *element; }
        const typename std::iterator_traits<ElementIterator>::pointer   operator-> () const { return element.ElementIterator::operator->(); }

        const JoinerIterator& operator++ () { // prefix
            inc();
            return *this;
        }

        JoinerIterator operator++ (int) { // postfix
            JoinerIterator res = *this;
            inc();
            return res;
        }

        bool operator== (const JoinerIterator& oth) const {
            return container == oth.container && (element == oth.element || container == container_end);
        }

        bool operator!= (const JoinerIterator& oth) const {
            return container != oth.container || (element != oth.element && container != container_end);
        }

        bool is_end () {
            return container == container_end;
        }

        void set_position (size_t global, size_t local) {
            //TODO: static_assert or enable if for random access iterators
            container = container_begin + global;
            element   = std::begin(*container) + local;
        }

    private:
        void inc () {
            ++element;
            find_new_begin();
        }

        void find_new_begin () {  // find first not empty range
            while (element == container->end()) {
                if (++container == container_end) {
                    break;
                }
                element = container->begin(); //std::begin(*container);
            }
        }
    };

    template <typename RoRIterator>
    struct JoinerRange {
        using Iterator = JoinerIterator<RoRIterator>;
        Iterator _begin;
        Iterator _end;
    };

    template <typename RoRIterator>
    JoinerRange<RoRIterator> joiner (RoRIterator begin, RoRIterator end) {
        return JoinerRange<RoRIterator>{ JoinerIterator<RoRIterator>(begin, end), JoinerIterator<RoRIterator>(end, end) };
    }

}}


namespace std {

    template <typename RoRIterator>
    struct iterator_traits<panda::ranges::JoinerIterator<RoRIterator> > {
        using Joiner = panda::ranges::JoinerIterator<RoRIterator>;
        typedef typename iterator_traits<typename Joiner::Container::iterator>::difference_type difference_type;
        typedef typename iterator_traits<typename Joiner::Container::iterator>::value_type value_type;
        typedef typename iterator_traits<typename Joiner::Container::iterator>::reference reference;
        typedef typename iterator_traits<typename Joiner::Container::iterator>::pointer pointer;
        typedef std::input_iterator_tag iterator_category;
    };

    template <typename Iterator>
    auto begin (panda::ranges::JoinerRange<Iterator> p) -> decltype(p._begin) {
        return p._begin;
    }

    template <typename Iterator>
    auto end (panda::ranges::JoinerRange<Iterator> p) -> decltype(p._end)  {
        return p._end;
    }

}
