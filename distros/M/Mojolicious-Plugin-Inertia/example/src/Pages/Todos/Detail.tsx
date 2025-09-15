import { Head, Link } from '@inertiajs/react'

interface Todo {
  id: number
  title: string
  completed: boolean
}

interface Props {
  todo: Todo | null
  errors: Record<string, string>
}

export default function TodoDetail({ todo, errors }: Props) {
  if (errors.todo) {
    return (
      <div className="min-h-screen bg-gray-50 py-12 px-4">
        <Head title="Todo Not Found" />
        <div className="max-w-2xl mx-auto">
          <div className="bg-red-50 border border-red-200 rounded-lg p-6">
            <h1 className="text-xl font-semibold text-red-800 mb-2">Error</h1>
            <p className="text-red-600">{errors.todo}</p>
            <Link
              href="/todos"
              className="inline-block mt-4 px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
            >
              Back to Todos
            </Link>
          </div>
        </div>
      </div>
    )
  }

  if (!todo) {
    return null
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4">
      <Head title={`Todo: ${todo.title}`} />
      <div className="max-w-2xl mx-auto">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
          <h1 className="text-2xl font-bold text-gray-900 mb-4">
            {todo.title}
          </h1>
          <p className="text-gray-600 mb-6">
            Status: {todo.completed ? 'Completed ✓' : 'Pending ○'}
          </p>
          <div className="flex gap-3">
            <button
              onClick={() => {
                fetch(`/todos/${todo.id}`, {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({
                    title: todo.title,
                    completed: !todo.completed
                  })
                }).then(() => window.location.href = '/todos')
              }}
              className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
            >
              {todo.completed ? 'Mark as Pending' : 'Mark as Complete'}
            </button>
            <Link
              href="/todos"
              className="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
            >
              Back to List
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}